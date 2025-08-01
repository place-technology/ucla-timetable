require "./spec_helper"

describe UCLA::Timetable do
  timetable = UCLA::Timetable.new("https://timetable.domain", "OEpidWT75Qd88nG", "GaW73MsBSq")

  it "authenticates" do
    now = Time.utc
    WebMock.stub(:post, "https://timetable.domain/oauth/client_credential/accesstoken?grant_type=client_credentials")
      .with(
        body: "scope=read",
        headers: {
          "Authorization" => "Basic T0VwaWRXVDc1UWQ4OG5HOkdhVzczTXNCU3E=",
          "Content-Type"  => "application/x-www-form-urlencoded",
          "Accept"        => "application/json, text/plain, text/json, */*",
        }
      ).to_return(body: %({
        "refresh_token_expires_in":"0",
        "api_product_list":"[Dictionary-QA, Classes-QA, Instructors, Verify Connectivity to SIS-QA, Courses-QA]",
        "api_product_list_json":["[Dictionary-QA, Classes-QA, Instructors, Verify Connectivity to SIS-QA, Courses-QA]"],
        "organization_name":"ucla",
        "developer.email":"",
        "token_type":"Bearer",
        "issued_at":"#{now.to_unix}",
        "client_id":"OEpidWT7nUgAfzD3fZZtcK6vO5Qd88nG",
        "access_token":"Kmty8zGrTMibvx806cBXe3NTARbx",
        "refresh_token":"",
        "application_name":"a13e367c-2010-4ecd-8673-c888cc79be1a",
        "scope":"",
        "expires_in":"3599",
        "refresh_count":"0",
        "status":"approved"
      }))

    timetable.get_access_token.should eq "Kmty8zGrTMibvx806cBXe3NTARbx"
  end

  it "finds the active term" do
    WebMock.stub(:get, "https://timetable.domain/sis/dictionary/#{Time.utc.to_s("%m-%d-%Y")}/RG/activeacademicterm/v1")
      .to_return(body: %({
        "activeAcademicTerm":[{
          "inputDate":"08-01-2025",
          "termSessionDate":"RG",
          "termCode":"25F",
          "termSequenceNumber":"285",
          "termSessionStartDate":"2025-06-14",
          "termSessionLastDate":"2025-12-12"
        }]
      }))
    term = timetable.get_active_term
    term.term_code.should eq "25F"
  end

  it "obtains the term details" do
    WebMock.stub(:get, "https://timetable.domain/sis/dictionary/terms/v1?TermCode=25F")
      .to_return(body: %({
        "lastCachedAt":"2025-08-01T00:54:41.9415684-07:00",
        "terms":[{"termCode":"25F","termName":"FALL 2025","academicYear":"2025-2026","termSequenceNumber":"285","cssTermCode":"252"}],
        "totalRecords":1,
        "totalPages":1,
        "pageNumber":1,
        "pageSize":10,
        "links":[{"href":"https://qa.api.ucla.edu/sis/dictionary/terms/v1?pagenumber=1&pagesize=10","rel":"self","method":"GET"}]
      }))
    term_details = timetable.get_term_details("25F")
    term_details.term_name.should eq "FALL 2025"
  end

  it "lists classes" do
    WebMock.stub(:get, "https://timetable.domain/sis/classes/25F/v1?pagesize=100")
      .to_return(body: %({
        "lastCachedAt": "2025-08-01T01:13:58.4049563-07:00",
        "classes": [
          {
            "dataDisclosureWarning": "WARNING: This payload may include class information that is not published in the Schedule of Classes. The classSessionDisplayFormat field will return “Official Format” if it is published in the Schedule of Classes. This field will return “Do not display”, “Tentative Format” or “History” if it is not published in the Schedule of Classes.",
            "offeredTermCode": "25F",
            "subjectAreaCode": "A&O SCI",
            "courseCatalogNumber": "0001",
            "courseCatalogNumberDisplay": "1",
            "courseStartTermCode": "04F",
            "classSessionDisplayFormat": "Official Format",
            "termSessionGroupCollection": [
              {
                "termsessionGroupCode": "",
                "termsessionInstructionWeeks": "10",
                "termsessionGroupWeekCode": "10",
                "classCollection": [
                  {
                    "classNumber": "001",
                    "links": [
                      {
                        "href": "https://qa.api.ucla.edu/sis/classes/25f/a%26o%20sci/0001/001/classdetail/v1",
                        "rel": "classDetail",
                        "method": "GET"
                      },
                      {
                        "href": "https://qa.api.ucla.edu/sis/classsections/25f/a%26o%20sci/0001/001/v1",
                        "rel": "classSections",
                        "method": "GET"
                      }
                    ]
                  }
                ]
              }
            ],
            "links": [
              {
                "href": "https://qa.api.ucla.edu/sis/courses/a%26o%20sci/0001/04f/coursedetail/v1",
                "rel": "courseDetail",
                "method": "GET"
              }
            ]
          }
        ],
        "totalRecords": 3358,
        "totalPages": 3358,
        "pageNumber": 1,
        "pageSize": 1,
        "links": [
          {
            "href": "https://qa.api.ucla.edu/sis/classes/25f/v1?pagenumber=1&pagesize=100",
            "rel": "self",
            "method": "GET"
          }
        ]
      }))
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
    WebMock.stub(:get, "https://timetable.domain/sis/classes/25F/a%26o%20sci/0001/001/classdetail/v1")
      .to_return(body: %({
        "classDetail": {
          "dataDisclosureWarning": "WARNING: This payload may include class detail information that is not published in the Schedule of Classes. The classSessionDisplayFormat field will return “Official Format” if it is published in the Schedule of Classes. This field will return “Do not display”, “Tentative Format” or “History” if it is not published in the Schedule of Classes.",
          "offeredTermCode": "25F",
          "subjectAreaCode": "A&O SCI",
          "courseCatalogNumber": "0001",
          "courseStartTermCode": "04F",
          "classNumber": "001",
          "classNumberDisplay": "1",
          "classDescription": "",
          "classNotesCollection": [
            {
              "classNotes": ""
            }
          ],
          "classTitle": "Climate Change: From Puzzles to Policy",
          "classSessionCode": "RG",
          "classSessionDisplayFormat": "Official Format",
          "classSchedulePrintCode": "",
          "classStartDate": "2025-09-25",
          "classEndDate": "2025-12-05",
          "classWebsite": "",
          "classTextbook": "https://shib.asucla.ucla.edu/CourseRedirect/CoursesRed.html?catids=25F126004200",
          "classMultipleTermGradingCode": "",
          "links": [
            {
              "href": "https://qa.api.ucla.edu/sis/classes/25f/a%26o%20sci/0001/001/classfinalexam/v1",
              "rel": "classFinalExam",
              "method": "GET"
            }
          ]
        }
      }))
    class_details = timetable.get_class_details("25F", "a%26o%20sci", "0001", "001")
  end
end
