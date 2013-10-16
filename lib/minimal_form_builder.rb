class MinimalFormBuilder < SimpleForm::FormBuilder
  def input(attribute_name, options = {}, &block)
    if options[:placeholder].nil?
      options[:placeholder] ||= object.class.human_attribute_name(attribute_name)
    end
    options[:label] = false if options[:label].nil?

    super
  end
end