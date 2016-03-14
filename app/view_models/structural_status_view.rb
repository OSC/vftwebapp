class StructuralStatusView < ViewModel
  def subject
    thermal.structural
  end

  def msg
    if subject.active?
      view_context.content_tag :p do
        "Submitted..."
      end
    elsif subject.failed?
      view_context.content_tag :p do
        subject.fail_msg
      end
    end
  end
end
