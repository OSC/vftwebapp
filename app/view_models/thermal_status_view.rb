class ThermalStatusView < ViewModel
  def subject
    thermal
  end

  def msg
    if active?
      "Submitted..."
    elsif failed?
      fail_msg
    end
  end
end
