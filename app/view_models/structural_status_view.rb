class StructuralStatusView < ViewModel
  def subject
    thermal.structural
  end

  def msg
    if subject.active? && !subject.running?
      view_context.content_tag :p do
        "Submitted..."
      end
    elsif subject.active?
      cur_profile = subject.cur_profile || 0
      num_profile = subject.num_profile || 1
      percent = cur_profile * 100 / num_profile
      view_context.content_tag :div, class: 'progress' do
        view_context.content_tag :div, class: 'progress-bar progress-bar-primary progress-bar-striped', role: 'progressbar', style: "width: #{percent}%" do
          "#{percent}%"
        end
      end
    elsif subject.failed?
      view_context.content_tag :p do
        subject.fail_msg
      end
    end
  end
end
