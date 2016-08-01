class SessionSerializer < ActiveModel::Serializer
  attributes :id, :staged_dir, :state, :stage, :status, :fails, :created_at, :updated_at, :links

  def staged_dir
    object.staged_dir.to_s
  end

  def stage
    case object.state
    when 'vftsolid', 'vftsolid_active', 'vftsolid_failed'
      {step: 1, name: 'VFTSolid'}
    when 'thermal', 'thermal_active', 'thermal_failed'
      {step: 2, name: 'Thermal'}
    when 'structural', 'structural_active', 'structural_failed'
      {step: 3, name: 'Structural'}
    else
      {step: 4, name: 'Results'}
    end
  end

  def status
    {
      active: object.active?,
      not_submitted: object.not_submitted?,
      failed: object.failed?,
      complete: object.complete?,
      name:
        if object.not_submitted?
          "Not Submitted"
        elsif object.failed?
          "Failed"
        elsif object.complete?
          "Completed"
        else
          if object.session_job
            object.session_job.status.to_s
          else
            "Bad state"
          end
        end,
      percent:
        if object.structural_active?
          step, total = object.parse_warp3d_log_file
          step * 100 / total
        else
          nil
        end
    }
  end

  def links
    {
      self: session_url(object, only_path: true),
      edit: edit_session_url(object, only_path: true),
      submit: submit_session_url(object, only_path: true),
      validate: validate_session_url(object, only_path: true),
      back: back_session_url(object, only_path: true),
      skip: skip_session_url(object, only_path: true),
      stop: stop_session_url(object, only_path: true),
      conn: object.vftsolid_conn_view ? object.vftsolid_conn_view.render(:awesim) : nil,
      t_paraview: object.thermal_paraview? ? thermal_paraview_session_url(object, only_path: true) : nil,
      s_paraview: object.structural_paraview? ? structural_paraview_session_url(object, only_path: true) : nil
    }
  end
end
