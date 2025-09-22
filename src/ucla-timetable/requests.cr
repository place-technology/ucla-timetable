require "./models/*"

class UCLA::Timetable
  # Use default param for date
  def get_active_term(date : Time = Time.utc) : ActiveTerm
    term = request NamedTuple(activeAcademicTerm: Array(ActiveTerm)), "/sis/dictionary/#{date.to_s("%m-%d-%Y")}/RG/activeacademicterm/v1"
    term[:activeAcademicTerm][0]
  end

  def term_param(term : String) : String
    term_code_pattern = /^\d{2}[A-Za-z]$/    # Matches "25W"
    term_name_pattern = /^[A-Za-z]+\s\d{4}$/ # Matches "Winter 2025"

    URI::Params.build do |form|
      if term_code_pattern.matches?(term)
        form.add "TermCode", term
      elsif term_name_pattern.matches?(term)
        form.add "TermName", term
      else
        raise "Invalid Term format: #{term}"
      end
    end
  end

  # Use presence to detect provided term, default empty
  def get_term_details(term : String? = nil) : TermDetails
    code = term.presence || get_active_term.term_code
    request(TermsResponse, "/sis/dictionary/terms/v1?#{term_param(code)}").terms[0]
  end

  def list_classes(term : String? = nil) : ClassResponse
    code = term.presence || get_active_term.term_code
    request(ClassResponse, "/sis/classes/#{code}/v1?pagesize=100").set_timetable(self)
  end

  def get_class_details(
    offered_term_code : String,
    subject_area_code : String,
    course_catalog_number : String,
    class_number : String,
  ) : ClassDetails
    request(NamedTuple(classDetail: ClassDetails), "/sis/classes/#{offered_term_code}/#{subject_area_code}/#{course_catalog_number}/#{class_number}/classdetail/v1")[:classDetail]
  end

  def get_class_section(
    offered_term_code : String,
    subject_area_code : String,
    course_catalog_number : String,
    class_number : String,
  ) : ClassSection
    request(NamedTuple(classSection: ClassSection), "/sis/classsections/#{offered_term_code}/#{subject_area_code}/#{course_catalog_number}/#{class_number}/v1")[:classSection]
  end

  def get_class_section_details(
    offered_term_code : String,
    subject_area_code : String,
    course_catalog_number : String,
    class_section_number : String,
  ) : SectionDetail
    request(NamedTuple(classSectionDetail: SectionDetail), "/sis/classsections/#{offered_term_code}/#{subject_area_code}/#{course_catalog_number}/#{class_section_number}/classsectiondetail/v1")[:classSectionDetail]
  end

  def get_instructor_details(
    ucla_id : String | Int64,
  ) : Instructor?
    # we return nil here on error as it's not critical information and we don't have API access currently
    # also the sample code I am referencing also does something similar
    request(Instructor, "/sis/instructors/#{ucla_id}/v1", cache: "instruct-#{ucla_id}") rescue nil
  end
end
