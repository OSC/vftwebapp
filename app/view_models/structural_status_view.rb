class StructuralStatusView < ViewModel
  def subject
    thermal.structural
  end

  def msg
    if subject.active?
      "Submitted..."
    elsif subject.failed?
      subject.fail_msg
    end
  end
end
