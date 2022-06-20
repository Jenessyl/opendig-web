module ApplicationHelper

  def stratigraphic_relationships
    DataDigger.stratigraphy_related_how
  end

  def stratigraphy_relatation_types
    DataDigger.stratigraphy_related_type
  end

  def all_loci
    Locus.all
  end

  def survey_instruments
    DataDigger.survey_instruments
  end

  def pot_form
    Rails.application.config.descriptions['lookups']['pot_form']
  end

  def age
    Rails.application.config.descriptions['lookups']['age']
  end

  def time_level
    Rails.application.config.descriptions['lookups']['time_level']
  end

  def question
    Rails.application.config.descriptions['lookups']['question']
  end

  def sanitize_locus(locus)
    locus.gsub(/\D/,'.') if locus
  end

  def flash_class(level)
    case level
    when :notice then "alert alert-info"
    when :success then "alert alert-success"
    when :error then "alert alert-error"
    when :alert then "alert alert-error"
    end
  end

  def level_or_nil(level)
    if level == "0" || nil
      "-"
    else
      level
    end
  end

  def read_date(date_string)
    if date_string.present?
      Date.parse(date_string).strftime('%d %b, %Y')
    else
      nil
    end
  end

  def output(value, type)
    case type
    when 'date'
      read_date value if value
    else
      value
    end
  end

  def input_for(form_definition_hash, value, description_type)
    case form_definition_hash["type"]
    when "picker"
      select_tag "locus[#{description_type}][#{form_definition_hash['key']}]", options_for_select(form_definition_hash['values'], value), include_blank: true, class: "form-control"
    when "text_field"
      text_field_tag "locus[#{description_type}][#{form_definition_hash['key']}]", value, class: "form-control"
    when "date"
      "N/A"
    when "checkbox"
      check_box_tag "locus[#{description_type}][#{form_definition_hash['key']}]", true, false, :class => 'form-control'
    when "text_area"
      text_area_tag "locus[#{description_type}][#{form_definition_hash['key']}]", value, class: "form-control"
    end
  end

end
