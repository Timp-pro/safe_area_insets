// ignore_for_file: avoid_web_libraries_in_flutter, unused_element, unused_element_parameter

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:web/web.dart' hide CSS;

// Definir las funciones JS de forma más directa
@JS('addEventListener')
external void _addEventListener(JSString type, JSFunction listener, [JSAny? options]);

@JS('removeEventListener')
external void _removeEventListener(JSString type, JSFunction listener, [JSAny? options]);

// Extensión corregida para EventTarget
extension EventTargetExt on EventTarget {
  Disposable listenEvent(
      String type,
      JsEventListener listener, [
        JSAny? options,
      ]) {
    final jsListener = listener.toJS;
    final jsType = type.toJS;

    // Llamar directamente en el contexto del elemento
    if (options != null) {
      (this as JSObject).callMethod('addEventListener'.toJS, jsType, jsListener, options);
      return () => (this as JSObject).callMethod('removeEventListener'.toJS, jsType, jsListener, options);
    } else {
      (this as JSObject).callMethod('addEventListener'.toJS, jsType, jsListener);
      return () => (this as JSObject).callMethod('removeEventListener'.toJS, jsType, jsListener);
    }
  }
}

typedef Disposable = void Function();
typedef JsEventListener = void Function(JSAny? event);

// Opciones tipadas para addEventListener con nombre único
@JS()
@anonymous
extension type CustomAddEventListenerOptions._(JSObject _) implements JSObject {
  external bool? get once;
  external set once(bool? v);
  external bool? get passive;
  external set passive(bool? v);
  external bool? get capture;
  external set capture(bool? v);
  external factory CustomAddEventListenerOptions({bool? once, bool? passive, bool? capture});
}

// Extensión para CSS usando JS directo con nombre único
class CustomCSS {
  static bool supports(String property, String value) {
    return (globalContext['CSS'] as JSObject).callMethod('supports'.toJS, property.toJS, value.toJS) as bool;
  }

  static bool supportsCondition(String conditionText) {
    return (globalContext['CSS'] as JSObject).callMethod('supports'.toJS, conditionText.toJS) as bool;
  }
}

// Extensiones adicionales para Element usando JS directo
extension ElementExt on Element {
  CSSStyleDeclaration getComputedStyle() {
    return globalContext.callMethod('getComputedStyle'.toJS, this as JSObject) as CSSStyleDeclaration;
  }
}

// Extensión para CSSStyleDeclaration para obtener valores como double
extension CSSStyleDeclarationExt on CSSStyleDeclaration {
  double? get insetValue {
    final value = paddingBottom;
    if (!value.endsWith('px')) {
      return null;
    }
    return double.tryParse(value.substring(0, value.length - 2));
  }
}

@visibleForTesting
void testJsExt() {
  final div = document.createElement('div') as HTMLElement;
  div.id = 'js_ext_test';
  div.textContent = 'click to hide me';
  final style = div.style;
  style.backgroundColor = 'red';
  style.color = 'white';
  style.position = 'fixed';
  style.top = '20px';
  style.right = '20px';
  style.padding = '10px';
  style.cursor = 'pointer';
  style.zIndex = '9999';

  div.listenEvent('click', (event) {
    div.remove();
  });

  document.body!.appendChild(div);
}