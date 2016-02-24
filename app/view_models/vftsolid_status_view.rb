class VftsolidStatusView < ViewModel
  def status_str
    starting? ? "Starting" : status.to_s
  end

  def conn_avail?
    active? && running? && ! starting?
  end

  def msg
    "The weld passes are a mess!" if failed?
  end
end
