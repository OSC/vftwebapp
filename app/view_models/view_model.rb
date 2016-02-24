class ViewModel < SimpleDelegator
  def to_partial_path
    "sessions/#{self.class.name.underscore}"
  end
  
  def workflow_stage
    ""
  end

  def self.for_session(session)
    thermal = session.thermal
    structural = thermal ? session.thermal.structural : nil

    if ! session.submitted?
      VftsolidFormView.new(session)
    elsif session.running? || session.failed?
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
