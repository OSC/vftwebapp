class ThermalStatusView < ViewModel
  def subject
    thermal
  end

  def msg
    if subject.active?
      "Submitted..."
    elsif subject.failed?
      fail_msg
    end
  end
end
