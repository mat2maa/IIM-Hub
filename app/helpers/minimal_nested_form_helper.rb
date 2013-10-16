require 'minimal_nested_form_builder'
module MinimalNestedFormHelper
  def minimal_nested_form_for(object, *args, &block)
    options = args.extract_options!
    simple_nested_form_for(object, *(args << options.merge(:builder => MinimalNestedFormBuilder)), &block)
  end
end