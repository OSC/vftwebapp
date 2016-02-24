class ViewModel < SimpleDelegator
  def to_partial_path
    "sessions/#{self.class.name.underscore}"
  end
  
  #FIXME: should the subclasses specify these?
  def workflow_stage
    return "1/3" if [VftsolidFormView, VftsolidStatusView].include? self.class
    return "2/3" if [ThermalFormView, ThermalStatusView].include? self.class
    return "3/3" if [StructuralFormView, StructuralStatusView].include? self.class

    "Results:"
  end

  def row_bg
    self.class == ResultsView ? "" : "bg-warning"
  end

  def self.for_session(session)
    thermal = session.thermal
    structural = thermal ? session.thermal.structural : nil

    if ! session.submitted?
      VftsolidFormView.new(session)
    elsif session.active? || session.failed?
      VftsolidStatusView.new(session)
    elsif session.passed? && ! thermal.submitted?
      ThermalFormView.new(session)
    elsif thermal && (thermal.active? || thermal.failed?)
      ThermalStatusView.new(session)
    elsif thermal && (thermal.passed? && ! structural.submitted?)
      StructuralFormView.new(session)
    elsif structural && (structural.active? || structural.failed?)
      StructuralStatusView.new(session)
    else
      ResultsView.new(session)
    end
  end
end
