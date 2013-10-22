# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  include ModalOverlayHelper

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end

  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"))
  end
  
  def character_count(field_id, update_id, options = {})
    function = "$('#{update_id}').innerHTML = $F('#{field_id}').length;"
    out = javascript_tag(function) # set current length
    out += observe_field(field_id, options.merge(:function => function)) # and observe it
  end

  def error_messages_for(object)
    if object.errors.any?
      render partial: "shared/errors", object: object.errors
    end

  end

  def autotab
    @current_tab ||= 0
    @current_tab += 1
  end

  def empty_blank_params(hash)
    if hash.present?
      hash.delete_if { |k, v| v.blank? && v != false }
    else
      hash
    end
  end
end
