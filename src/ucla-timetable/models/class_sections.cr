class UCLA::Timetable
  # https://developer.api.ucla.edu/api/261#/Class%20Sections/ClassSections_GetClassSections
  struct ClassSection
    include JSON::Serializable

    @[JSON::Field(key: "offeredTermCode")]
    getter offered_term_code : String

    @[JSON::Field(key: "subjectAreaCode")]
    getter subject_area_code : String

    @[JSON::Field(key: "courseCatalogNumber")]
    getter course_catalog_number : String

    @[JSON::Field(key: "courseStartTermCode")]
    getter start_term_code : String

    @[JSON::Field(key: "classNumber")]
    getter class_number : String

    @[JSON::Field(key: "classSectionSessionDisplayFormat")]
    getter class_section_session_display_format : String

    @[JSON::Field(key: "classSectionCollection")]
    getter section_collection : Array(SectionNumber)

    def class_section_numbers
      section_collection.map(&.section_number)
    end

    def class_section_detail_links
      section_collection.map do |klass|
        klass.links.find! { |link| link.rel == "classSectionDetail" }.href
      end
    end

    def class_section_details : Array(Tuple(String, String, String, String))
      class_section_numbers.map do |number|
        {offered_term_code, subject_area_code, course_catalog_number, number}.map { |segment| URI.encode_path_segment(segment) }
      end
    end

    def class_section_details(timetable : Timetable) : Array(SectionDetail)
      class_section_detail_links.map do |link|
        timetable.request(NamedTuple(classSectionDetail: SectionDetail), link)[:classSectionDetail]
      end
    end
  end

  struct SectionNumber
    include JSON::Serializable

    @[JSON::Field(key: "classSectionNumber")]
    getter section_number : String

    # rels:
    # classSectionDetail: /sis/classsections/25f/a%26o%20sci/0001/001e/classsectiondetail/v1
    getter links : Array(Link)
  end

  struct SectionDetail
    include JSON::Serializable

    @[JSON::Field(key: "offeredTermCode")]
    getter offered_term_code : String

    @[JSON::Field(key: "subjectAreaCode")]
    getter subject_area_code : String

    @[JSON::Field(key: "courseCatalogNumber")]
    getter course_catalog_number : String

    @[JSON::Field(key: "courseStartTermCode")]
    getter start_term_code : String

    @[JSON::Field(key: "classSectionNumber")]
    getter section_number : String

    @[JSON::Field(key: "classSectionNumberDisplay")]
    getter section_number_display : String

    @[JSON::Field(key: "classSectionID")]
    getter class_section_id : String

    @[JSON::Field(key: "classSectionSessionDisplayFormat")]
    getter session_display_format : String

    @[JSON::Field(key: "concurrentEnrollmentFlag")]
    getter concurrent_enrollment_flag : String

    @[JSON::Field(key: "classSectionActivityCode")]
    getter section_activity_code : String

    @[JSON::Field(key: "classSectionActivityEnrollmentSequenceNumber")]
    getter section_activity_enrollment_sequence_number : String

    @[JSON::Field(key: "classSectionPrimaryActivityFlag")]
    getter section_primary_activity_flag : String

    @[JSON::Field(key: "classSectionGradeTypeCode")]
    getter section_grade_type_code : String

    @[JSON::Field(key: "classSectionUnitTypeCode")]
    getter section_unit_type_code : String

    @[JSON::Field(key: "classSectionOnlineFlag")]
    getter section_online_flag : String

    @[JSON::Field(key: "classSectionEnrollmentStatusCode")]
    getter enrollment_status_code : String

    @[JSON::Field(key: "classSectionSchedulePrintCode")]
    getter schedule_print_code : String

    # List of instructors running the course
    @[JSON::Field(key: "instructorUCLAIDCollection")]
    getter instructors : Array(InstructorUCLAID)

    @[JSON::Field(key: "classSectionCombinedMeetingId")]
    getter section_combined_meeting_id : String

    # List of meeting rooms
    @[JSON::Field(key: "classSectionMeetingCollection")]
    getter meeting_rooms : Array(SectionMeetingRoom)
  end

  struct InstructorUCLAID
    include JSON::Serializable

    @[JSON::Field(key: "uclaid")]
    getter ucla_id : String

    # it's called links but only has a single link
    @[JSON::Field(key: "links")]
    getter link : Link
  end

  struct SectionMeetingRoom
    include JSON::Serializable

    @[JSON::Field(key: "classSectionMeetingDaysofWeekCode")]
    getter days_of_week_code : String

    @[JSON::Field(key: "classSectionMeetingStartTime")]
    getter start_time : String

    @[JSON::Field(key: "classSectionMeetingStopTime")]
    getter stop_time : String

    @[JSON::Field(key: "classSectionBuildingCode")]
    getter building_code : String

    @[JSON::Field(key: "classSectionBuildingRoomCode")]
    getter room_code : String
  end
end
