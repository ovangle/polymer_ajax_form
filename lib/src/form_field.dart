library polymer_ajax_form.form_field;

import 'dart:html';

import '../form_input.dart';

//TODO: Image buttons not handled correctly.
// According to WHATWG spec, an input type=image
// needs to be inserted with two names, name + 'x' and name + 'y'
// which contain the x and y coordinates respectively.


class FormField {
  /// Input element types which are always unsuccessful
  static const _UNSUCCESSFUL_TYPES = const ['button', 'submit', 'reset'];

  /// Collects the successful controls from the children of
  /// the given element.
  static Iterable<FormField> collectFields(Element element) {
    var field = fromControl(element);
    if (field != null) {
      return field.isSuccessful ? <FormField>[field] : <FormField>[];
    }

    // Don't collect children of a <datalist>
    if (element is DataListElement)
      return <FormField>[];

    // Don't collect children of a disabled fieldset
    // unless they are children of its first <legend>
    if (element is FieldSetElement && element.disabled) {
      var legend = element.querySelector('legend');
      if (legend != null) {
        return collectFields(legend);
      } else {
        return <FormField>[];
      }
    }

    if (element.shadowRoot != null) {
      return element.shadowRoot.children.expand(collectFields);
    }

    if (element is ShadowElement) {
      // There is no need to descend into the shadow root.
      // shadow.getDistributedNodes() will already include any content
      // nodes in the older shadow root.
      return element.getDistributedNodes()
          .where((node) => node is Element)
          .expand((elem) => collectFields(elem));
    }

    if (element is ContentElement) {
      // The distributed nodes of a Content element exist in the light DOM,
      // so the [:root:] of the element must be `null`.
      print('${element.getDistributedNodes()
                .where((node) => node is Element)
                .map((node) => node.name)}');
      return element.getDistributedNodes()
          .where((node) => node is Element)
          .expand((elem) => collectFields(elem));
    }

    return element.children.expand(collectFields);
  }

  static FormField fromControl(dynamic control) {
    if (control is InputElement) {
      return new FormField.fromInputElement(control);
    } else if (control is FormInput) {
      return new FormField.fromFormInput(control);
    } else if (control is SelectElement) {
      return new FormField.fromSelectElement(control);
    } else if (control is TextAreaElement) {
      return new FormField.fromTextAreaElement(control);
    }
    return null;
  }

  final String type;

  final String name;
  final dynamic value;

  final bool disabled;
  final bool valid;

  // A flag which indicates that this is a file field.
  bool get isFile => type == 'file';

  bool get isSuccessful {
    if (_UNSUCCESSFUL_TYPES.contains(type))
      return false;
    if (name == null || name.isEmpty)
      return false;
    if (type == 'checkbox' || type == 'radio')
      return value != null;
    return !disabled && valid;
  }

  FormField._(
      this.type, this.name, this.value,
      {this.disabled, this.valid});

  FormField.fromFormInput(FormInput node):
    this._(
        'custom',
         node.name, node.value,
         disabled: node.disabled,
         valid: node.valid
    );

  FormField.fromInputElement(InputElement node):
    this._(
        node.type,
        node.name, _inputElementValue(node),
        disabled: node.disabled,
        valid: node.formNoValidate || node.validity.valid
     );

  FormField.fromSelectElement(SelectElement node):
    this._(
        'select',
         node.name, _selectElementValue(node),
         disabled: node.disabled,
         valid: node.validity.valid
    );
  FormField.fromTextAreaElement(TextAreaElement node):
    this._(
        'textarea',
        node.name, node.value,
        disabled: node.disabled,
        valid: node.validity.valid
     );
}


_inputElementValue(InputElement element) {
  switch(element.type) {
    case 'button':
    case 'submit':
    case 'reset':
      return null;
    case 'file':
      return element.files;
    case 'radio':
    case 'checkbox':
      return element.checked ? element.value : null;
    case 'number':
    case 'range':
      if (element.value == null || element.value.isEmpty)
        return element.value;
      return num.parse(element.value);
    default:
      return element.value;
  }
}

_selectElementValue(SelectElement element) {
  String getOptionValue(OptionElement option) {
    if (option.value == null || option.value.isEmpty)
      return option.text;
    return option.value;
  }
  if (element.multiple) {
    return element.selectedOptions.map((getOptionValue))
        .toList(growable: false);
  } else {
    return getOptionValue(element.options[element.selectedIndex]);
  }

}