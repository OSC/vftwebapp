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
    return "1/3" if [VftsolidFormView, VftsolidStatusView].include? self.class
    return "2/3" if [ThermalFormView, ThermalStatusView].include? self.class
    return "3/3" if [StructuralFormView, StructuralStatusView].include? self.class

    "Results:"
  end

  def row_bg
    self.class == ResultsView ? "" : "bg-warning"
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
