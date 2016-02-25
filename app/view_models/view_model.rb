class ViewModel < SimpleDelegator
  attr_reader :view_context

  def initialize(obj, view_context)
    super(obj)
    @view_context = view_context
  end

  def to_partial_path
    "sessions/#{self.class.name.underscore}"
  end

  #FIXME: the subclasses should specify these?
  def workflow_stage
    return "1/3<br>VFTSolid".html_safe if [VftsolidFormView, VftsolidStatusView].include? self.class
    return "2/3<br>Thermal".html_safe if [ThermalFormView, ThermalStatusView].include? self.class
    return "3/3<br>Structural".html_safe if [StructuralFormView, StructuralStatusView].include? self.class

    "Results:"
  end

  #FIXME: the subclasses should specify these?
  def workflow_status
    s = view_context.status_label(self).html_safe

    s = view_context.status_label(self).html_safe if [VftsolidFormView, VftsolidStatusView].include? self.class
    s = view_context.status_label(thermal).html_safe if [ThermalFormView, ThermalStatusView].include? self.class
    s = view_context.status_label(thermal.structural).html_safe if [StructuralFormView, StructuralStatusView].include? self.class

    s
  end

  # the subject of the workflow stage is
  # either the session, or session.thermal, or sesion.thermal.structural
  def subject
    self
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
