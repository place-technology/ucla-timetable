require "./spec_helper"

describe UCLA::Timetable do
  timetable = UCLA::Timetable.new("https://timetable.domain", "OEpidWT75Qd88nG", "GaW73MsBSq")

  it "authenticates" do
    UCLA.stub_access_token
    timetable.get_access_token.should eq "Kmty8zGrTMibvx806cBXe3NTARbx"
  end

  it "finds the active term" do
    UCLA.stub_active_term
    term = timetable.get_active_term
    term.term_code.should eq "25F"
  end

  it "obtains the term details" do
    UCLA.stub_term_details
    term_details = timetable.get_term_details("25F")
    term_details.term_name.should eq "FALL 2025"
  end

  it "lists classes" do
    UCLA.stub_list_classes
    response = timetable.list_classes
    response.classes.first.subject_area_code.should eq "A&O SCI"

    published = [] of UCLA::Timetable::ClassInfo
    response.each_published do |klass|
      published << klass
    end
    published.size.should eq 1
    published.first.should eq response.classes.first
  end

  it "obtains class details" do
    UCLA.stub_list_classes
    response = timetable.list_classes
    klass = response.classes.first

    UCLA.stub_class_details
    class_details = timetable.get_class_details(*klass.class_details.first)
    class_details.class_number_display.should eq "1"

    UCLA.stub_class_details
    class_details = klass.class_details(timetable).first
    class_details.class_number_display.should eq "1"
  end

  it "lists class sections" do
    UCLA.stub_list_classes
    response = timetable.list_classes
    klass = response.classes.first

    UCLA.stub_class_sections
    section = klass.class_sections(timetable).first
    section.class_section_numbers.should eq ["001"]

    UCLA.stub_class_sections
    section = timetable.get_class_section(*klass.class_details.first)
    section.class_section_detail_links.should eq ["https://timetable.domain/sis/classsections/25F/A%26O%20SCI/0001/001/classsectiondetail/v1"]
  end

  it "obtains class section details" do
    UCLA.stub_list_classes
    response = timetable.list_classes
    klass = response.classes.first

    UCLA.stub_class_sections
    section = klass.class_sections(timetable).first

    UCLA.stub_class_section_details
    details = timetable.get_class_section_details(*section.class_section_details.first)

    UCLA.stub_class_section_details
    details = klass.class_section_details(timetable).first
    meeting_room = details.meeting_rooms.first
    meeting_room.days_of_week.should eq [Time::DayOfWeek::Tuesday, Time::DayOfWeek::Thursday]

    # check that it can expand the events in a defined period
    tz = UCLA::Timetable::TIMEZONE
    starting = Time.local(UCLA::Timetable::TIMEZONE).at_beginning_of_week
    ending = starting.at_end_of_week

    tuesday_start = Time.parse("#{(starting + 1.day).to_s("%Y-%m-%d")} 11:00AM", "%Y-%m-%d %I:%M%p", tz)
    tuesday_end = Time.parse("#{(starting + 1.day).to_s("%Y-%m-%d")} 12:15PM", "%Y-%m-%d %I:%M%p", tz)
    thursday_start = Time.parse("#{(starting + 3.days).to_s("%Y-%m-%d")} 11:00AM", "%Y-%m-%d %I:%M%p", tz)
    thursday_end = Time.parse("#{(starting + 3.days).to_s("%Y-%m-%d")} 12:15PM", "%Y-%m-%d %I:%M%p", tz)

    results = [
      UCLA::Timetable::CalendarEntry.new("HAINES", "00220", tuesday_start, tuesday_end),
      UCLA::Timetable::CalendarEntry.new("HAINES", "00220", thursday_start, thursday_end),
    ]
    meeting_room.expand_range(starting, ending).should eq results
  end
end
