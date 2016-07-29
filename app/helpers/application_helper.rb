module ApplicationHelper
  def flash_type_to_alert(type)
    case type
    when :notice
      return :success
    when :info
      return :info
    when :alert
      return :warning
    when :error
      return :danger
    else
      return type
    end
  end
end
