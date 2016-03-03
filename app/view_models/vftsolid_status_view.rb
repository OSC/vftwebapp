class VftsolidStatusView < ViewModel
  def status_str
    starting? ? "Starting" : status.to_s
  end

  def conn_avail?
    active? && running? && ! starting?
  end

  def msg
    if starting?
      view_context.link_to view_context.icon('spinner', "Starting VFTSolid", class: 'fa-spin'), '#', class: 'btn btn-default btn-sm disabled'
    elsif queued?
      "Submitted VFTSolid..."
    elsif failed?
      fail_msg
    end
  end
end
