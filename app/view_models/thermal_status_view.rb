class ThermalStatusView < ViewModel
  def subject
    thermal
  end

  def msg
    if subject.active?
      view_context.content_tag :p do
        "Submitted..."
      end
    elsif subject.failed?
      msg = view_context.content_tag :p do
        subject.fail_msg
      end
    end
  end
end
