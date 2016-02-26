class ViewModel < SimpleDelegator
  attr_reader :view_context

  def initialize(obj, view_context)
    super(obj)
    @view_context = view_context
  end

  def to_partial_path
    "sessions/#{self.class.name.underscore}"
  end

  #FIXME: the subclasses should specify these; even tiny duplication is OK - for
  #the benefit of flexibility of diverting in the future
  def workflow_stage
    total = 4

    if [VftsolidFormView, VftsolidStatusView].include? self.class
      current = 1
      text = "VFTSolid"
    elsif [ThermalFormView, ThermalStatusView].include? self.class
      current = 2
      text = "Thermal"
    elsif [StructuralFormView, StructuralStatusView].include? self.class
      current = 3
      text = "Structural"
    else
      current = 4
      text = "Results"
    end

    view_context.render partial: "stages_ctrl", locals: { current: current, total: total, text: text }
  end

  # the subject of the workflow stage is
  # either the session, or session.thermal, or sesion.thermal.structural
  def subject
    self
  end

  def workflow_status
    view_context.status_label(subject).html_safe
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
