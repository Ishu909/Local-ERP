#!/bin/bash

# Helper functions
function normalize_input() {
    echo "$1" | tr -d '\r' | xargs
}

function safe_file_read() {
    local filename="$1"
    [ ! -f "$filename" ] && return 1
    sed '1s/^\xEF\xBB\xBF//; s/\r$//' "$filename"
}

function head_banner() {
    clear
    echo "============================================="
    echo "           Academic Tool System"
    echo "============================================="
    echo "Developed by (Sudo Students) [All rights reserved]"
    echo
}

function send_email() {
    local recipient="$1"
    local subject="$2"
    local body="$3"
    
    (
        echo "Subject: $subject"
        echo "To: $recipient"
        echo "From: academic_system@university.edu"
        echo
        echo "$body"
        echo
    ) | msmtp "$recipient" 2>/dev/null
}

# Core functions
function return_function_value() {
    local INPUT="$1.csv"
    [ ! -f "$INPUT" ] && { echo "0"; return; }
    
    local search_id=$(normalize_input "$2")
    local field_num=$3
    local result="0"

    while IFS=',' read -r line; do
        line=$(normalize_input "$line")
        IFS=',' read -ra fields <<< "$line"
        local current_id=$(normalize_input "${fields[0]}")
        
        if [ "$current_id" == "$search_id" ]; then
            case $1 in
                "teacher") result="${fields[$((field_num-1))]}" ;;
                "student") result="${fields[$((field_num-1))]}" ;;
                "semester"|"course") result="${fields[$((field_num-1))]}" ;;
            esac
            break
        fi
    done < <(safe_file_read "$INPUT")
    
    echo "$(normalize_input "$result")"
}

function create_semester() {
    echo "Enter the semester session(Spring/Fall):"
    read -r semester_session
    echo "Enter the semester year:"
    read -r semester_year
    semester=$(normalize_input "$semester_session-$semester_year")

    while IFS= read -r line; do
        if [ "$(normalize_input "$line")" == "$semester" ]; then
            echo "Semester Already Exists"
            return 1
        fi
    done < <(safe_file_read "semester.csv")

    echo "$semester" >> semester.csv
    echo "$semester Semester Created successfully"
}

function create_teacher_user() {
    echo "Enter teacher id:"
    read -r user_id
    echo "Enter teacher name:"
    read -r user_name
    echo "Enter Department:"
    read -r user_dept
    echo "Enter Subject:"
    read -r user_subject
    echo "Enter Email:"
    read -r user_email
    user_id=$(normalize_input "$user_id")
    existing=$(return_function_value teacher "$user_id" 1)

    if [ "$existing" == "0" ]; then
        echo "$user_id,$user_name,$user_dept,$user_subject,$user_email" >> teacher.csv

        (
        echo "Subject: Faculty Registration Done Successfully!!"
        echo "To: $user_email"
        echo "From: newtech@gmail.com"
        echo
        echo "Hello $user_name,"
        echo
        echo "Your teacher account has been created successfully."
        echo
        echo "Teacher ID: $user_id"
        echo
        echo "Department: $user_dept"
        echo
        echo "Subject: $user_subject"
        echo
        echo "Thank you!"
        ) | msmtp "$user_email"

        # send_email "$user_email" "Teacher Account Created" "$email_body"
        echo "Teacher $user_id created successfully"
    else
        echo "Teacher $user_id already exists"
    fi
}

function create_student_user() {
    echo "Enter student id:"
    read -r user_id
    echo "Enter student name:"
    read -r user_name
    echo "Enter Course:"
    read -r user_course
    echo "Enter Department:"
    read -r user_dept
    echo "Enter University Rollno:"
    read -r user_univ_rollno
    echo "Enter Contact no:"
    read -r user_contact_no
    echo "Enter E-mail:"
    read -r user_email

    user_id=$(normalize_input "$user_id")
    existing=$(return_function_value student "$user_id" 1)

    if [ "$existing" == "0" ]; then
        echo "$user_id,$user_name,$user_course,$user_dept,$user_univ_rollno,$user_contact_no,$user_email" >> student.csv
        (
        echo "Subject: Your Registration is Done Successfully!!"
        echo "To: $user_email"
        echo "From: newtech@gmail.com"
        echo
        echo "Hello $user_name,"
        echo
        echo "Your student account has been created successfully."
        echo
        echo "Student ID: $user_id"
        echo
        echo "Course: $user_course"
        echo
        echo "Department: $user_dept"
        echo
        echo "University Roll No: $user_univ_rollno"
        echo
        echo "Please maintain good attendance to avoid penalties."
        ) | msmtp "$user_email"
        # send_email "$user_email" "Student Account Created" "$email_body"
        echo "Student $user_id created successfully"
    else
        echo "Student $user_id already exists"
    fi
}

function create_course() {
    echo "Enter course id:"
    read -r course_id
    echo "Enter course name:"
    read -r course_name
    echo "Enter teacher id:"
    read -r user_teacher_id
    echo "Enter semester(Spring-2023):"
    read -r create_course_semester

    course_id=$(normalize_input "$course_id")
    teacher_name=$(return_function_value teacher "$user_teacher_id" 2)
    semester_exists=$(grep -Fxq "$create_course_semester" <(safe_file_read "semester.csv"); echo $?)

    if [ -n "$teacher_name" ] && [ "$teacher_name" != "0" ] && [ "$semester_exists" -eq 0 ]; then
        echo "$course_id,$course_name,$create_course_semester,$user_teacher_id" >> course.csv
        echo "Course $course_id created successfully"
    else
        echo "Validation failed:"
        [ -z "$teacher_name" ] || [ "$teacher_name" == "0" ] && echo "- Teacher not found"
        [ "$semester_exists" -ne 0 ] && echo "- Semester not found"
    fi
}

function modify_teacher() {
    echo "==== Modify Courses Teacher ===="
    view_courses
    echo "Enter course id:"
    read -r user_course_id
    echo "Enter semester:"
    read -r user_semester
    echo "Enter new teacher id:"
    read -r user_new_teacher_id

    user_course_id=$(normalize_input "$user_course_id")
    user_semester=$(normalize_input "$user_semester")
    user_new_teacher_id=$(normalize_input "$user_new_teacher_id")

    new_teacher_name=$(return_function_value teacher "$user_new_teacher_id" 2)

    if [ -n "$new_teacher_name" ] && [ "$new_teacher_name" != "0" ]; then
        while IFS=',' read -r c_id c_name c_sem t_id; do
            if [ "$(normalize_input "$c_id")" == "$user_course_id" ] && 
               [ "$(normalize_input "$c_sem")" == "$user_semester" ]; then
                echo "$c_id,$c_name,$c_sem,$user_new_teacher_id" >> temp_course.csv
            else
                echo "$c_id,$c_name,$c_sem,$t_id" >> temp_course.csv
            fi
        done < <(safe_file_read "course.csv")

        mv temp_course.csv course.csv
        echo "Teacher successfully modified"
    else
        echo "New teacher not found"
    fi
}

function delete_student() {
    echo "==== Delete Student ===="
    view_students
    
    echo "Enter student id to delete:"
    read -r user_delete_student_id
    user_delete_student_id=$(normalize_input "$user_delete_student_id")

    student_name=$(return_function_value student "$user_delete_student_id" 2)

    if [ -n "$student_name" ] && [ "$student_name" != "0" ]; then
        # Delete from student.csv
        while IFS=',' read -r s_id s_name s_course s_dept s_roll s_contact s_email; do
            if [ "$(normalize_input "$s_id")" != "$user_delete_student_id" ]; then
                echo "$s_id,$s_name,$s_course,$s_dept,$s_roll,$s_contact,$s_email" >> temp_student.csv
            fi
        done < <(safe_file_read "student.csv")

        # Delete from courseEnroll.csv
        while IFS=',' read -r c_id s_id sem att quiz mid final; do
            if [ "$(normalize_input "$s_id")" != "$user_delete_student_id" ]; then
                echo "$c_id,$s_id,$sem,$att,$quiz,$mid,$final" >> temp_enroll.csv
            fi
        done < <(safe_file_read "courseEnroll.csv")

        mv temp_student.csv student.csv
        mv temp_enroll.csv courseEnroll.csv
        echo "Student $user_delete_student_id deleted successfully"
    else
        echo "Student not found"
    fi
}

function enroll_course() {
    echo "=============== Enroll into the course ==============="
    view_courses
    
    echo "Enter course id:"
    read -r user_course_id
    echo "Enter student id:"
    read -r user_student_id
    echo "Enter semester:"
    read -r user_semester

    user_course_id=$(normalize_input "$user_course_id")
    user_student_id=$(normalize_input "$user_student_id")
    user_semester=$(normalize_input "$user_semester")

    # Check existence
    semester_exists=$(grep -Fxq "$user_semester" <(safe_file_read "semester.csv"); echo $?)
    student_exists=$(return_function_value student "$user_student_id" 1)
    course_exists=$(return_function_value course "$user_course_id" 1)

    if [ "$semester_exists" -eq 0 ] && [ "$student_exists" != "0" ] && [ "$course_exists" != "0" ]; then
        # Check duplicate enrollment
        while IFS=',' read -r c_id s_id sem att quiz mid final; do
            if [ "$(normalize_input "$c_id")" == "$user_course_id" ] &&
               [ "$(normalize_input "$s_id")" == "$user_student_id" ] &&
               [ "$(normalize_input "$sem")" == "$user_semester" ]; then
                echo "Student already enrolled"
                return 1
            fi
        done < <(safe_file_read "courseEnroll.csv")

        echo "$user_course_id,$user_student_id,$user_semester,0,0,0,0" >> courseEnroll.csv
        echo "Enrollment successful"
    else
        echo "Validation failed:"
        [ "$semester_exists" -ne 0 ] && echo "- Semester not found"
        [ "$student_exists" == "0" ] && echo "- Student not found"
        [ "$course_exists" == "0" ] && echo "- Course not found"
    fi
}

# View functions
function view_teachers() {
    echo -e "\n============================================= View Teachers =============================================\n"
    echo -e "ID\tName\t\tDepartment\tSubject\t\tEmail\n"

    while IFS=',' read -r t_id t_name t_dept t_subject t_email; do
        printf "%-8s\t%-12s\t%-12s\t%-12s\t%s\n" "$t_id" "$t_name" "$t_dept" "$t_subject" "$t_email"
    done < <(safe_file_read "teacher.csv")
}

function view_students() {
    echo -e "\n================================================ View Students ================================================\n"
    echo -e "ID\t\tName\t\tCourse\t\tDepartment\tRoll No\t\tContact\t\tEmail\n"

    while IFS=',' read -r s_id s_name s_course s_dept s_roll s_contact s_email; do
        printf "%-8s\t%-12s\t%-8s\t%-12s\t%-8s\t%-12s\t%s\n" \
               "$s_id" "$s_name" "$s_course" "$s_dept" "$s_roll" "$s_contact" "$s_email"
    done < <(safe_file_read "student.csv")
}

function view_semesters() {
    echo -e "\n============================================= View Semesters =============================================\n"
    cat -b semester.csv
}

function view_courses() {
    echo -e "\n============================================= View Courses =============================================\n"
    echo -e "Sl: ID\t\tName\t\t\tSemester\tTeacher\t\tEnrolled\n"

    local count=0
    while IFS=',' read -r c_id c_name c_sem t_id; do
        count=$((count+1))
        t_name=$(return_function_value teacher "$t_id" 2)
        enrolled=$(grep -c "^$c_id," courseEnroll.csv 2>/dev/null || echo 0)
        printf "%2d : %-8s\t%-20s\t%-12s\t%-12s\t%3d\n" "$count" "$c_id" "$c_name" "$c_sem" "$t_name" "$enrolled"
    done < <(safe_file_read "course.csv")
}

function view_course_enrollments() {
    echo -e "\n============================================= View Enrollments =============================================\n"
    echo -e "Sl: CID\t\tSID\t\tSemester\tCourse Name\t\tStudent Name\tAttendance\n"

    local count=0
    while IFS=',' read -r c_id s_id sem att quiz mid final; do
        count=$((count+1))
        c_name=$(return_function_value course "$c_id" 2)
        s_name=$(return_function_value student "$s_id" 2)
        attendance_percentage=$((att * 100 / 15))
        printf "%2d : %-8s\t%-8s\t%-12s\t%-20s\t%-12s\t%2d%%\n" "$count" "$c_id" "$s_id" "$sem" "$c_name" "$s_name" "$attendance_percentage"
    done < <(safe_file_read "courseEnroll.csv")
}

function teacher_course_enrolled_students() {
    local teacher_id="$1"
    echo -e "\n============================================= Your Course Students =============================================\n"
    echo -e "Sl: CID\t\tCourse\t\tSID\t\tStudent\t\tAttendance%\t(Quiz,Mid,Final)\n"

    local count=0
    while IFS=',' read -r c_id c_name c_sem t_id; do
        if [ "$(normalize_input "$t_id")" == "$teacher_id" ]; then
            while IFS=',' read -r ce_cid s_id sem att quiz mid final; do
                if [ "$(normalize_input "$ce_cid")" == "$(normalize_input "$c_id")" ]; then
                    count=$((count+1))
                    s_name=$(return_function_value student "$s_id" 2)
                    attendance_percentage=$((att * 100 / 15))
                    printf "%2d : %-8s\t%-12s\t%-8s\t%-12s\t%3d%%\t\t%2d,%2d,%2d\n" \
                           "$count" "$c_id" "$c_name" "$s_id" "$s_name" "$attendance_percentage" "$quiz" "$mid" "$final"
                fi
            done < <(safe_file_read "courseEnroll.csv")
        fi
    done < <(safe_file_read "course.csv")
}

function teacher_course_students_marks() {
    local teacher_id="$1"
    teacher_course_enrolled_students "$teacher_id"
    
    echo -e "\n==== Update Student Marks ===="
    echo "Enter course id:"
    read -r course_id
    echo "Enter student id:"
    read -r student_id
    echo "Enter semester:"
    read -r semester

    course_id=$(normalize_input "$course_id")
    student_id=$(normalize_input "$student_id")
    semester=$(normalize_input "$semester")

    # Verify this is the teacher's course
    valid_course=0
    while IFS=',' read -r c_id c_name c_sem t_id; do
        if [ "$(normalize_input "$c_id")" == "$course_id" ] && 
           [ "$(normalize_input "$t_id")" == "$teacher_id" ]; then
            valid_course=1
            break
        fi
    done < <(safe_file_read "course.csv")

    if [ "$valid_course" -eq 0 ]; then
        echo "You are not assigned to this course"
        return
    fi

    echo "Enter attendance classes attended (0-15):"
    read -r att
    echo "Enter quiz marks (0-15):"
    read -r quiz
    echo "Enter midterm marks (0-30):"
    read -r mid
    echo "Enter final marks (0-40):"
    read -r final

    # Validate marks
    if [ "$att" -gt 15 ] || [ "$quiz" -gt 15 ] || [ "$mid" -gt 30 ] || [ "$final" -gt 40 ]; then
        echo "Invalid marks (max: attendance=15, quiz=15, mid=30, final=40)"
        return
    fi

    # Update marks
    while IFS=',' read -r c_id s_id sem old_att old_quiz old_mid old_final; do
        if [ "$(normalize_input "$c_id")" == "$course_id" ] && 
           [ "$(normalize_input "$s_id")" == "$student_id" ] && 
           [ "$(normalize_input "$sem")" == "$semester" ]; then
            echo "$c_id,$s_id,$sem,$att,$quiz,$mid,$final" >> temp_enroll.csv
            echo "Marks updated successfully"
            
            # Check attendance and send email if below 75%
            attendance_percentage=$((att * 100 / 15))
            if [ "$attendance_percentage" -lt 75 ]; then
                student_email=$(return_function_value student "$student_id" 7)
                student_name=$(return_function_value student "$student_id" 2)
                course_name=$(return_function_value course "$course_id" 2)
                
                # email_subject="Low Attendance Warning - $course_name"
                (
                echo "Subject: Low Attendance Warning"
                echo "To: $user_email"
                echo "From: newtech@gmail.com"
                echo
                echo "Dear $student_name"
                echo
                echo "Your attendance in $course_name is currently $attendance_percentage%, which is below the required 75%.Please improve your attendance to avoid academic penalties."
                echo
                echo "Regards,"
                echo "Academic System"
                ) | msmtp "$student_email"

                # send_email "$student_email" "$email_subject" "$email_body"
                echo "Low attendance warning sent to student"
            fi
        else
            echo "$c_id,$s_id,$sem,$old_att,$old_quiz,$old_mid,$old_final" >> temp_enroll.csv
        fi
    done < <(safe_file_read "courseEnroll.csv")

    mv temp_enroll.csv courseEnroll.csv
}

function check_low_attendance() {
    echo -e "\n============================================= Low Attendance Students =============================================\n"
    echo -e "Sl: CID\t\tCourse\t\tSID\t\tStudent\t\tAttendance%\tEmail\n"

    local count=0
    while IFS=',' read -r c_id s_id sem att quiz mid final; do
        attendance_percentage=$((att * 100 / 15))
        if [ "$attendance_percentage" -lt 75 ]; then
            count=$((count+1))
            c_name=$(return_function_value course "$c_id" 2)
            s_name=$(return_function_value student "$s_id" 2)
            s_email=$(return_function_value student "$s_id" 7)
            
            printf "%2d : %-8s\t%-12s\t%-8s\t%-12s\t%3d%%\t\t%s\n" \
                   "$count" "$c_id" "$c_name" "$s_id" "$s_name" "$attendance_percentage" "$s_email"
        fi
    done < <(safe_file_read "courseEnroll.csv")

    if [ "$count" -eq 0 ]; then
        echo "No students with attendance below 75%"
    fi
}

function view_student_search() {
    echo -e "\n============================================= Search Student =============================================\n"
    echo "Enter student id:"
    read -r student_id
    student_id=$(normalize_input "$student_id")

    s_name=$(return_function_value student "$student_id" 2)
    if [ -z "$s_name" ] || [ "$s_name" == "0" ]; then
        echo "Student not found"
        return
    fi

    echo -e "\nStudent: $s_name ($student_id)"
    echo -e "Courses:\n"
    echo -e "CID\tCourse\t\tSemester\tAtt%\tQuiz\tMid\tFinal\tGrade"

    while IFS=',' read -r c_id s_id sem att quiz mid final; do
        if [ "$(normalize_input "$s_id")" == "$student_id" ]; then
            c_name=$(return_function_value course "$c_id" 2)
            total=$((att + quiz + mid + final))
            attendance_percentage=$((att * 100 / 15))
            
            if [ $total -ge 80 ]; then grade="A+"
            elif [ $total -ge 75 ]; then grade="A"
            elif [ $total -ge 70 ]; then grade="A-"
            elif [ $total -ge 65 ]; then grade="B+"
            elif [ $total -ge 60 ]; then grade="B"
            elif [ $total -ge 55 ]; then grade="B-"
            elif [ $total -ge 50 ]; then grade="C+"
            elif [ $total -ge 45 ]; then grade="C"
            elif [ $total -ge 40 ]; then grade="D"
            else grade="F"
            fi

            printf "%-8s\t%-12s\t%-12s\t%3d%%\t%2d\t%2d\t%2d\t%s\n" \
                   "$c_id" "$c_name" "$sem" "$attendance_percentage" "$quiz" "$mid" "$final" "$grade"
        fi
    done < <(safe_file_read "courseEnroll.csv")
}

# Menu functions
function admin_menu() {
    while true; do
        head_banner
        echo "=============== Admin Menu ==============="
        echo "1. Create Teacher"
        echo "2. View Teachers"
        echo "3. Create Student"
        echo "4. View Students"
        echo "5. Search Student"
        echo "6. Create Semester"
        echo "7. View Semesters"
        echo "8. Create Course"
        echo "9. View Courses"
        echo "10. Modify Course Teacher"
        echo "11. Enroll Student"
        echo "12. View Enrollments"
        echo "13. Delete Student"
        echo "14. Check Low Attendance Students"
        echo "15. Back to Main"
        echo "=========================================="
        read -rp "Enter choice: " choice

        case "$choice" in
            1) create_teacher_user ;;
            2) view_teachers ;;
            3) create_student_user ;;
            4) view_students ;;
            5) view_student_search ;;
            6) create_semester ;;
            7) view_semesters ;;
            8) create_course ;;
            9) view_courses ;;
            10) modify_teacher ;;
            11) enroll_course ;;
            12) view_course_enrollments ;;
            13) delete_student ;;
            14) check_low_attendance ;;
            15) break ;;
            *) echo "Invalid choice" ;;
        esac
        read -rp "Press Enter to continue..."
    done
}

function teacher_menu() {
    echo "Enter teacher id:"
    read -r teacher_id
    teacher_id=$(normalize_input "$teacher_id")

    t_name=$(return_function_value teacher "$teacher_id" 2)
    if [ -z "$t_name" ] || [ "$t_name" == "0" ]; then
        echo "Teacher not found"
        return
    fi

    while true; do
        head_banner
        echo -e "=============== Teacher Menu ($t_name) ==============="
        echo "1. View Your Course Students"
        echo "2. Update Student Marks"
        echo "3. Back to Main"
        echo "=========================================="
        read -rp "Enter choice: " choice

        case "$choice" in
            1) teacher_course_enrolled_students "$teacher_id" ;;
            2) teacher_course_students_marks "$teacher_id" ;;
            3) break ;;
            *) echo "Invalid choice" ;;
        esac
        read -rp "Press Enter to continue..."
    done
}

function student_menu() {
    echo "Enter student id:"
    read -r student_id
    student_id=$(normalize_input "$student_id")

    s_name=$(return_function_value student "$student_id" 2)
    if [ -z "$s_name" ] || [ "$s_name" == "0" ]; then
        echo "Student not found"
        return
    fi

    view_student_search "$student_id"
    read -rp "Press Enter to continue..."
}

# Main program
function main() {
    # Initialize required files if they don't exist
    for file in teacher.csv student.csv semester.csv course.csv courseEnroll.csv; do
        [ ! -f "$file" ] && touch "$file"
    done

    while true; do
        head_banner
        echo "1. Admin"
        echo "2. Teacher"
        echo "3. Student"
        echo "4. Exit"
        read -rp "Enter choice: " choice

        case "$choice" in
            1) 
                echo "Enter admin password:"
                read -r password
                [ "$password" == "admin123" ] && admin_menu || echo "Invalid password"
                ;;
            2) teacher_menu ;;
            3) student_menu ;;
            4) exit 0 ;;
            *) echo "Invalid choice" ;;
        esac
    done
}

main