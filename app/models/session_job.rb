class SessionJob < Job
  belongs_to :workflow, class_name: "Session"
end
