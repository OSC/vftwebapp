class VftsolidStatusView < ViewModel
  def status_str
    starting? ? "Starting" : status.to_s
  end

  def conn_avail?
    active? && running? && ! starting?
  end

  def msg
    if starting?
      "Starting..."
    elsif queued?
      "Submitted VFTSolid..."
    elsif failed?
      fail_msg
    end
  end
end
