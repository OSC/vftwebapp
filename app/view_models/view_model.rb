class ViewModel < SimpleDelegator
  attr_reader :view_context

  def initialize(obj, view_context)
    super(obj)
    @view_context = view_context
  end

  def to_partial_path
    "shared/#{self.class.name.underscore}"
  end

  def workflow_stage_name
    return @workflow_stage_name if @workflow_stage_name

    sn = ""
    if self.class.name =~ /(.*)(FormView|StatusView)$/
      sn = $1
    elsif self.class.name =~ /(.*)(View)$/
      sn = $1
    end

    @workflow_stage_name ||= (sn == "Vftsolid" ? "VFTSolid" : sn)
  end

  def workflow_stage
    total = 4

    #FIXME: dangerous superclass knowledge of subclasses
    current = ["vftsolid", "thermal", "structural", "results"].find_index(workflow_stage_name.downcase)+1
    class_name = "stage-#{workflow_stage_name.downcase}"

    view_context.content_tag("div", view_context.content_tag("badge", current, class: "badge") + " " + workflow_stage_name, class: class_name)
  end

  # the subject of the workflow stage is
  # either the session, or session.thermal, or sesion.thermal.structural
  def subject
    self
  end

  def workflow_status
    view_context.content_tag :div, class: 'status-label' do
      view_context.status_label(subject).html_safe
    end
  end

  def row_bg
    self.subject.failed? ? "" : "bg-warning"
  end

  def self.for_session(session, view_context)
    thermal = session.thermal
    structural = thermal ? session.thermal.structural : nil

    if ! session.submitted?
      VftsolidFormView.new(session, view_context)
    elsif session.active? || session.failed?
      VftsolidStatusView.new(session, view_context)
    elsif session.passed? && ! thermal.submitted?
      ThermalFormView.new(session, view_context)
    elsif thermal && (thermal.active? || thermal.failed?)
      ThermalStatusView.new(session, view_context)
    elsif thermal && (thermal.passed? && ! structural.submitted?)
      StructuralFormView.new(session, view_context)
    elsif structural && (structural.active? || structural.failed?)
      StructuralStatusView.new(session, view_context)
    else
      ResultsView.new(session, view_context)
    end
  end
end
