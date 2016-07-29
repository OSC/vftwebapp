class Session < ActiveRecord::Base
  include AASM

  belongs_to :mesh
  has_one :session_job, dependent: :destroy

  enum state: {
    vftsolid: 0,
    vftsolid_active: 1,
    vftsolid_failed: 2,
    thermal: 10,
    thermal_active: 11,
    thermal_failed: 12,
    structural: 20,
    structural_active: 21,
    structural_failed: 22,
    complete: 100
  }

  aasm column: :state, enum: true do
    state :vftsolid, initial: true
    state :vftsolid_active
    state :vftsolid_failed
    state :thermal
    state :thermal_active
    state :thermal_failed
    state :structural
    state :structural_active
    state :structural_failed
    state :complete

    event :submit do
      transitions from: :vftsolid, to: :vftsolid_active
      transitions from: :thermal, to: :thermal_active
      transitions from: :structural, to: :structural_active
    end

    event :succeed do
      transitions from: :vftsolid_active, to: :thermal
      transitions from: :thermal_active, to: :structural
      transitions from: :structural_active, to: :complete
    end

    event :fail do
      transitions from: :vftsolid_active, to: :vftsolid_failed
      transitions from: :thermal_active, to: :thermal_failed
      transitions from: :structural_active, to: :structural_failed
    end

    event :back do
      transitions from: :thermal, to: :vftsolid
      transitions from: :structural, to: :thermal
      transitions from: :complete, to: :structural
    end
  end
end
