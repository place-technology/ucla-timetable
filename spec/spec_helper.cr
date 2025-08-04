require "spec"
require "../src/ucla-timetable"

require "webmock"

Log.setup(:trace)

Spec.before_suite do
  Log.setup(:trace)
end

module UCLA
  def self.stub_access_token
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
  end

  def self.stub_active_term
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
  end

  def self.stub_term_details
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
  end

  def self.stub_list_classes
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
                        "href": "https://timetable.domain/sis/classes/25F/A%26O%20SCI/0001/001/classdetail/v1",
                        "rel": "classDetail",
                        "method": "GET"
                      },
                      {
                        "href": "https://timetable.domain/sis/classsections/25F/A%26O%20SCI/0001/001/v1",
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
                "href": "https://timetable.domain/sis/courses/A%26O%20SCI/0001/04F/coursedetail/v1",
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
            "href": "https://timetable.domain/sis/classes/25f/v1?pagenumber=1&pagesize=100",
            "rel": "self",
            "method": "GET"
          }
        ]
      }))
  end

  def self.stub_class_details
    WebMock.stub(:get, "https://timetable.domain/sis/classes/25F/A%26O%20SCI/0001/001/classdetail/v1")
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
          "classTextbook": "https://timetable.domain/CourseRedirect/CoursesRed.html?catids=25F126004200",
          "classMultipleTermGradingCode": "",
          "links": [
            {
              "href": "https://timetable.domain/sis/classes/25F/A%26O%20SCI/0001/001/classfinalexam/v1",
              "rel": "classFinalExam",
              "method": "GET"
            }
          ]
        }
      }))
  end

  def self.stub_class_sections
    WebMock.stub(:get, "https://timetable.domain/sis/classsections/25F/A%26O%20SCI/0001/001/v1")
      .to_return(body: %({
        "classSection": {
          "dataDisclosureWarning": "WARNING: This payload may include class section information that is not published in the Schedule of Classes. The classSectionSessionDisplayFormat field will return “Official Format” if it is published in the Schedule of Classes. This field will return “Do not display”, “Tentative Format” or “History” if it is not published in the Schedule of Classes.",
          "offeredTermCode": "25F",
          "subjectAreaCode": "A&O SCI",
          "courseCatalogNumber": "0001",
          "courseStartTermCode": "04F",
          "classNumber": "001",
          "classSectionSessionDisplayFormat": "Official Format",
          "classSectionCollection": [
            {
              "classSectionNumber": "001",
              "links": [
                {
                  "href": "https://timetable.domain/sis/classsections/25F/A%26O%20SCI/0001/001/classsectiondetail/v1",
                  "rel": "classSectionDetail",
                  "method": "GET"
                }
              ]
            }
          ]
        }
      }))
  end

  def self.stub_class_section_details
    WebMock.stub(:get, "https://timetable.domain/sis/classsections/25F/A%26O%20SCI/0001/001/classsectiondetail/v1")
      .to_return(body: %({
        "lastCachedAt": "2025-08-01T01:14:07.3508394-07:00",
        "classSectionDetail": {
          "dataDisclosureWarning": "WARNING: This payload may include class section information that is not published in the Schedule of Classes. The classSectionSessionDisplayFormat field will return “Official Format” if it is published in the Schedule of Classes. This field will return “Do not display”, “Tentative Format” or “History” if it is not published in the Schedule of Classes.",
          "offeredTermCode": "25F",
          "subjectAreaCode": "A&O SCI",
          "courseCatalogNumber": "0001",
          "courseStartTermCode": "04F",
          "classSectionNumber": "001",
          "classSectionNumberDisplay": "1",
          "classSectionID": "126004200",
          "classSectionSessionDisplayFormat": "Official Format",
          "concurrentEnrollmentFlag": "N",
          "classSectionActivityCode": "LEC",
          "classSectionActivityEnrollmentSequenceNumber": "2",
          "classSectionPrimaryActivityFlag": "Y",
          "classSectionGradeTypeCode": "SO",
          "classSectionUnitTypeCode": "F",
          "classSectionUnitCollection": [
            {
              "classSectionUnit": "4.00"
            }
          ],
          "classSectionNotesCollection": [
            {
              "classSectionNotes": ""
            }
          ],
          "classSectionOnlineFlag": "N",
          "classEnrollmentRestrictionTextCollection": [
            {
              "classEnrollmentRestrictionText": "None",
              "classEnrollmentConsentRequiredCode": "",
              "classEnrollmentRuleID": ""
            }
          ],
          "classSectionEnrollmentStatusCode": "O",
          "classSectionEnrollmentCapacityNumber": "122",
          "classSectionEnrollmentTotal": "0",
          "classSectionUNEXEnrollmentTotal": "0",
          "classSectionProjectedEnrollmentNumber": "122",
          "classSectionCancelBefore3rdWeekFlag": "N",
          "classSectionWeek3EnrollmentNumber": "0",
          "classSectionWeek8EnrollmentNumber": "0",
          "classSectionWaitlistCapacityNumber": "30",
          "classSectionWaitlistTotal": "0",
          "classSectionSchedulePrintCode": "",
          "instructorUCLAIDCollection": [
            {
              "uclaid": "200399999",
              "links": {
                "href": "https://timetable.domain/sis/instructors/200399999/classes/v1",
                "rel": "Class Instructor",
                "method": "GET"
              }
            },
            {
              "uclaid": "706325117",
              "links": {
                "href": "https://timetable.domain/sis/instructors/706325117/classes/v1",
                "rel": "Class Instructor",
                "method": "GET"
              }
            }
          ],
          "classSectionCombinedMeetingId": "",
          "classSectionMeetingCollection": [
            {
              "classSectionMeetingDaysofWeekCode": "TR",
              "classSectionMeetingStartTime": "11:00AM",
              "classSectionMeetingStopTime": "12:15PM",
              "classSectionBuildingCode": "HAINES",
              "classSectionBuildingRoomCode": "00220"
            }
          ],
          "links": [
            {
              "href": "https://timetable.domain/sis/rosters/25F/A%26O%20SCI/0001/001/rosterbyclasssection/v1",
              "rel": "RosterByClassSection",
              "method": "GET"
            }
          ]
        }
      }))
  end

  def self.stub_instructor_details
    WebMock.stub(:get, "https://timetable.domain/sis/instructors/706325117/v1")
      .to_return(body: %({
        "name": [{"nameCollection": [{
          "firstName": "Steve",
          "lastName": "von"
        }]}]
      }))
  end
end
