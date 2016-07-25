class VftsolidStatusView < ViewModel
  def status_str
    starting? ? "Starting" : status.to_s
  end

  def conn_avail?
    active? && running? && ! starting?
  end

  def msg
    if starting?
      view_context.content_tag :p do
        view_context.link_to view_context.icon('spinner', "Starting VFTSolid", class: 'fa-spin'), '#', class: 'btn btn-default btn-sm btn-fixwidth disabled'
      end
    elsif queued?
      view_context.content_tag :p do
        "Submitted VFTSolid..."
      end
    elsif failed?
      msg = view_context.content_tag :p do
        subject.fail_msg
      end
      msg << view_context.link_to(view_context.icon('check-square-o', 'Check Again'), view_context.submit_session_path(self, {validate: true}), method: :put, class: 'btn btn-default btn-sm launch-btn btn-fixwidth', remote: true)
    end
  end
end
