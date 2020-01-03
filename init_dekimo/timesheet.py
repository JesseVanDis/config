#from selenium import webdriver
#wd = webdriver.Firefox()
#wd.page_source
#This example requires Selenium WebDriver 3.13 or newer

#pip install selenium
#pip3 install selenium

import time
import sys
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.expected_conditions import presence_of_element_located, text_to_be_present_in_element
from selenium.webdriver.firefox.options import Options

def getTagValue(tagString, index):
    if index > 0:
        pre = tagString[tagString.find(">")+1:]
        return getTagValue(pre, index-1)
    else:
        pre = tagString[tagString.find(">")+1:]
        return pre[:pre.find("<")]

def isMainPageFinished(pageHtml):
    return pageHtml.count("</tr></tbody></table>") > 0

def findCurrentLogs(mainPageHtml):
    def getDays(rowString):
        rawDays = rowString.split("<td")
        days = []
        for rawDay in rawDays:
            day = getTagValue(rawDay, 0)
            date = getTagValue(rawDay, 1)
            days.append((day, date))
        return days[1:]

    def getCells(rowString):
        cells = []
        rawCells = rowString.split("<td")
        for rawCell in rawCells:
            activity = getTagValue(rawCell, 0)
            activityShort = getTagValue(rawCell, 1)
            duration = getTagValue(rawCell, 2)
            if activity.count("Add new log") > 0:
                activity = ""
            if len(activity) == 0:
                cells.append(("", "", 0.0))
            else:
                cells.append((activity, activityShort, duration))
        return cells[1:]

    days = []
    cells = [[], [], [], [], [], [], []]
    lines = mainPageHtml.splitlines()
    for tableLine in lines:
        if tableLine.count("Tuesday") > 0:
            rows = tableLine.split("<tr>")
            days = getDays(rows[1])
            maxRows = len(rows)
            for x in range(1, maxRows-1):
                cellsOfRow = getCells(rows[x+1])
                for weekIndex in range(0, 7):
                    if len(cellsOfRow[weekIndex]) > 0:
                        cells[weekIndex].append(cellsOfRow[weekIndex])

    categorized = []
    for dayIndex in range(0, 7):
        day = days[dayIndex]
        activities = cells[dayIndex]
        categorized.append((day, activities))
    return categorized

def printWithBarEnd(line, barIndex, spacing = " ", endChar = "|"):
    lineLength = len(line)
    print(line, end = '')
    for x in range(lineLength, barIndex):
        print(spacing, end = '')
    print(endChar)

def printActivities(activities):
    if len(activities) > 0:
        lines = []
        maxLineLength = 0
        for dayData in activities:
            dayName = dayData[0][0]
            dayDate = dayData[0][1]
            dateDay = dayDate[:dayDate.find("/")]
            dateMonth = dayDate[dayDate.find("/")+1:]
            dateMonth = dateMonth[:dateMonth.find("/")]
            activitiesOfDay = dayData[1]

            activitiesString = ""
            for activity in activitiesOfDay:
                if len(activity[0]) > 0:
                    activitiesString = activitiesString + "{:<24}".format(activity[0] + "(" + activity[2] + ")")
            line = "| {:<20}".format(dateDay + "/" + dateMonth + " " + dayName) + ": " + activitiesString
            maxLineLength = max(len(line), maxLineLength)
            lines.append(line)

        maxLineLength = maxLineLength + 2
        printWithBarEnd(" ______" + str(activities[0][0][1]) + " to " + str(activities[len(activities)-1][0][1]), maxLineLength, "_", " ")
        printWithBarEnd("| ", maxLineLength)
        for line in lines:
            printWithBarEnd(line, maxLineLength)
        printWithBarEnd("|", maxLineLength, "_")

def getUserAndPass():
    username = ""
    password = ""

    for arg in sys.argv:
        if arg.count("user=") > 0:
            username = arg[arg.find("=")+1:]
        if arg.count("pass=") > 0:
            password = arg[arg.find("=")+1:]
            
    if len(username) == 0:
        try:
            f = open("usr")
            username = str(f.read())
            f.close()
        except IOError:
            username = input("Please enter your username:\n")
            fw = open("usr", "w")
            fw.write(username)
            fw.close()

    if len(password) == 0:
        try:
            f = open("pass")
            password = str(f.read())
            f.close()
        except IOError:
            password = input("Please enter your password:\n")
            fw = open("pass", "w")
            fw.write(password)
            fw.close()

    return (username, password)

def getWebLoggerUrl():
    userAndPass = getUserAndPass()
    return "https://" + userAndPass[0] + ":" + userAndPass[1] + "@router.dekimo.be/WebLogger"

def printActivitiesOfThisWeek():
    options = Options()
    options.headless = True
    with webdriver.Firefox(options=options) as driver:
        wait = WebDriverWait(driver, 10)
        driver.get(getWebLoggerUrl())
        first_result = wait.until(presence_of_element_located((By.ID, "weeklyoverviewtable")))

        isPageFinished = False
        for x in range(0, 1000):
            time.sleep(0.1)
            isPageFinished = isMainPageFinished(str(driver.page_source))
            if isPageFinished:
                break

    #    print(driver.page_source)
        activities = findCurrentLogs(str(driver.page_source))
        printActivities(activities)

if sys.argv.count("showThisWeek"):
    printActivitiesOfThisWeek()

#getUserAndPass()

#    wait = WebDriverWait(driver, 10)
#    driver.get("https://google.com/ncr")
#    driver.find_element_by_name("q").send_keys("cheese" + Keys.RETURN)
#    print(first_result.get_attribute("textContent"))
