class ViewModel < SimpleDelegator
  def to_partial_path
    "sessions/#{self.class.name.underscore}"
  end

  def self.for_session(session)
    if ! session.submitted?
      VftsolidFormView.new(session)
    elsif session.running? || session.failed?
      VftsolidStatusView.new(session)
    elsif session.passed? && ! thermal.submitted?
      ThermalFormView.new(session)
    elsif thermal.running? || thermal.failed?
      ThermalStatusView.new(session)
    elsif thermal.passed? && ! structural.submitted?
      StructuralFormView.new(session)
    elsif structural.running? || structural.failed?
      StructuralStatusView.new(session)
    else
      ResultsView.new(session)
    end
  end
end
