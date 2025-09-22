// ignore_for_file: avoid_web_libraries_in_flutter, avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'dart:core';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter/rendering.dart' show EdgeInsets;
import 'package:web/web.dart';

import 'js_ext.dart';

enum _InsetsAttr { top, left, right, bottom }

EdgeInsets _readInsets() {
  final styles = elementComputedStyle;
  return EdgeInsets.only(
    left: styles[_InsetsAttr.left]?.insetValue ?? 0.0,
    top: styles[_InsetsAttr.top]?.insetValue ?? 0.0,
    right: styles[_InsetsAttr.right]?.insetValue ?? 0.0,
    bottom: styles[_InsetsAttr.bottom]?.insetValue ?? 0.0,
  );
}

/// use Dart rewrite [safeAreaInsets](https://github.com/zhetengbiji/safeAreaInsets/blob/master/src/index.ts)
var inited = false;
var elementComputedStyle = <_InsetsAttr, CSSStyleDeclaration>{};
String? support;

String getSupport() {
  String support;
  if (CustomCSS.supportsCondition('top: env(safe-area-inset-top)')) {
    support = 'env';
  } else if (CustomCSS.supportsCondition(
    'top: constant(safe-area-inset-top)',
  )) {
    support = 'constant';
  } else {
    support = '';
  }
  return support;
}

void init() {
  if (!isSupported) {
    return;
  }

  void setStyle(Element el, Map<String, String> style) {
    style.forEach((key, value) {
      (el as HTMLElement).style.setProperty(key, value);
    });
  }

  final cbs = <VoidCallback>[];
  void parentReady([VoidCallback? callback]) {
    if (callback != null) {
      cbs.add(callback);
    } else {
      for (final cb in cbs) {
        cb();
      }
    }
  }

  void addChild(Element parent, _InsetsAttr attr) {
    final a1 = document.createElement('div');
    final a2 = document.createElement('div');
    final a1Children = document.createElement('div');
    final a2Children = document.createElement('div');
    const W = 100;
    // ignore: constant_identifier_names
    const MAX = 10000;
    final aStyle = <String, String>{
      'position': 'absolute',
      'width': '${W}px',
      'height': '200px',
      'box-sizing': 'border-box',
      'overflow': 'hidden',
      'padding-bottom': '$support(safe-area-inset-${attr.name})',
    };
    setStyle(a1, aStyle);
    setStyle(a2, aStyle);
    setStyle(a1Children, {
      'transition': '0s',
      'animation': 'none',
      'width': '400px',
      'height': '400px',
    });
    setStyle(a2Children, {
      'transition': '0s',
      'animation': 'none',
      'width': '250%',
      'height': '250%',
    });
    a1.appendChild(a1Children);
    a2.appendChild(a2Children);
    parent.appendChild(a1);
    parent.appendChild(a2);

    parentReady(() {
      final a1Html = a1 as HTMLElement;
      final a2Html = a2 as HTMLElement;
      a1Html.scrollTop = a2Html.scrollTop = MAX;
      var a1LastScrollTop = a1Html.scrollTop;
      var a2LastScrollTop = a2Html.scrollTop;

      JsEventListener onScroll(HTMLElement that) {
        return (ev) {
          if (that.scrollTop ==
              (that == a1Html ? a1LastScrollTop : a2LastScrollTop)) {
            return;
          }
          a1Html.scrollTop = a2Html.scrollTop = MAX;
          a1LastScrollTop = a1Html.scrollTop;
          a2LastScrollTop = a2Html.scrollTop;
          _attrChange(attr);
        };
      }

      // Convertir explícitamente a EventTarget para usar la extensión
      (a1 as EventTarget).listenEvent(
        'scroll',
        onScroll(a1Html),
        CustomAddEventListenerOptions(passive: true),
      );
      (a2 as EventTarget).listenEvent(
        'scroll',
        onScroll(a2Html),
        CustomAddEventListenerOptions(passive: true),
      );
    });

    final computedStyle = a1.getComputedStyle();
    elementComputedStyle[attr] = computedStyle;
  }

  final parentDiv = document.createElement('div');
  setStyle(parentDiv, {
    'position': 'absolute',
    'left': '0',
    'top': '0',
    'width': '0',
    'height': '0',
    'zIndex': '-1',
    'overflow': 'hidden',
    'visibility': 'hidden',
  });
  _InsetsAttr.values.forEach((key) {
    addChild(parentDiv, key);
  });
  document.body?.appendChild(parentDiv);
  parentReady();
  inited = true;
}

/// Read the current 'safe-area-insets'
EdgeInsets get safeAreaInsets {
  if (!inited) {
    init();
  }
  return _readInsets();
}

final _insetsStreamController = StreamController<EdgeInsets>.broadcast(
  onListen: () {
    if (!inited) {
      init();
    }
  },
  sync: true,
);

/// Listen to the changes of `safe-area-insets`
Stream<EdgeInsets> get safeAreaInsetsStream => _insetsStreamController.stream;

var changeAttrs = <_InsetsAttr>[];

void _attrChange(_InsetsAttr attr) {
  if (changeAttrs.isEmpty) {
    Timer(Duration.zero, () {
      if (changeAttrs.isEmpty) {
        return;
      }
      changeAttrs.clear();
      _insetsStreamController.add(_readInsets());
    });
  }
  changeAttrs.add(attr);
}

bool get isSupported => (support ??= getSupport()).isNotEmpty;

/// Set `viewport-fit=cover`
///
/// @see https://github.com/flutter/flutter/issues/84833#issuecomment-890540239
void setupViewportFit() {
  var viewport =
      document.querySelector('meta[name=viewport]') as HTMLMetaElement?;
  if (viewport == null) {
    viewport = document.createElement('meta') as HTMLMetaElement;
    viewport.name = 'viewport';
    document.head?.appendChild(viewport);
  }
  final attrs = <String, String>{};
  for (final keyValue
      in viewport.content.split(',').map((e) => e.trim().split('='))) {
    if (keyValue.length == 2) {
      attrs[keyValue[0]] = keyValue[1];
    }
  }

  if (attrs['viewport-fit'] != 'cover') {
    attrs['viewport-fit'] = 'cover';
    viewport.content = attrs.entries
        .map((e) => '${e.key}=${e.value}')
        .join(',');
  }
}