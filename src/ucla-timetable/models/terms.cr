class UCLA::Timetable
  struct ActiveTerm
    include JSON::Serializable

    @[JSON::Field(key: "inputDate")]
    getter input_date : String

    @[JSON::Field(key: "termSessionDate")]
    getter term_session_date : String

    @[JSON::Field(key: "termCode")]
    getter term_code : String

    @[JSON::Field(key: "termSequenceNumber")]
    getter term_sequence_number : String

    @[JSON::Field(key: "termSessionStartDate")]
    getter term_session_start_date : String

    @[JSON::Field(key: "termSessionLastDate")]
    getter term_session_last_date : String
  end

  struct TermDetails
    include JSON::Serializable

    @[JSON::Field(key: "termCode")]
    getter term_code : String # "25F"

    @[JSON::Field(key: "termName")]
    getter term_name : String # "FALL 2025"

    @[JSON::Field(key: "academicYear")]
    getter academic_year : String # "2025-2026"

    @[JSON::Field(key: "termSequenceNumber")]
    getter term_sequence_number : String # "285"

    @[JSON::Field(key: "cssTermCode")]
    getter css_term_code : String # "252"
  end

  # pagination helper
  struct TermsResponse < ListResponse
    getter terms : Array(TermDetails)
  end
end
