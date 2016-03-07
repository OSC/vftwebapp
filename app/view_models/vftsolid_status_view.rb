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
      msg = view_context.content_tag :p do
        subject.fail_msg
      end
      msg << view_context.link_to(view_context.icon('check-square-o', 'Re-Validate'), view_context.submit_session_path(self), method: :put, class: 'btn btn-default btn-sm launch-btn', remote: true)
    end
  end
end
