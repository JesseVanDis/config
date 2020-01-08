#from selenium import webdriver
#wd = webdriver.Firefox()
#wd.page_source
#This example requires Selenium WebDriver 3.13 or newer

#pip install selenium
#pip3 install selenium

import time
import sys
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.expected_conditions import presence_of_element_located, text_to_be_present_in_element
from selenium.webdriver.firefox.options import Options

verbose = sys.argv.count("v") or sys.argv.count("-v")

def printIfVerbose(text):
    if verbose:
        print(text)

def getTagValue(tagString, index):
    if index > 0:
        pre = tagString[tagString.find(">")+1:]
        return getTagValue(pre, index-1)
    else:
        pre = tagString[tagString.find(">")+1:]
        return pre[:pre.find("<")]

def isMainPageFinished(pageHtml):
    return pageHtml.count("</tr></tbody></table>") > 0

def waitUntilMainPageIsFinished(driver):
    isPageFinished = False
    for x in range(0, 1000):
        time.sleep(0.1)
        isPageFinished = isMainPageFinished(str(driver.page_source))
        if isPageFinished:
            break
    return isPageFinished

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
        defaultColor = '\033[00m' # https://misc.flogisoft.com/bash/tip_colors_and_formatting
        todayDay = datetime.today().strftime("%d")
        todayMonth = datetime.today().strftime("%m")
        for dayData in activities:
            dayName = dayData[0][0]
            dayDate = dayData[0][1]
            dateDay = dayDate[:dayDate.find("/")]
            dateMonth = dayDate[dayDate.find("/")+1:]
            dateMonth = dateMonth[:dateMonth.find("/")]
            activitiesOfDay = dayData[1]
            isToday = todayDay == dateDay and todayMonth == dateMonth

            color = defaultColor
            if dayName == "Saturday" or dayName == "Sunday":
                color = '\033[90m'

            if isToday:
                color = '\033[04m'

            activitiesString = ""
            for activity in activitiesOfDay:
                if len(activity[0]) > 0:
                    activitiesString = activitiesString + "{:<24}".format(activity[0] + "(" + activity[2] + ")")
            if isToday:
                line = "| " + color + "{:<25}".format(dateDay + "/" + dateMonth + " " + dayName + defaultColor) + ": " + activitiesString
            else:	
                line = "| " + color + "{:<20}".format(dateDay + "/" + dateMonth + " " + dayName) + ": " + activitiesString + defaultColor
            maxLineLength = max(len(line), maxLineLength)

            lines.append(line)

        maxLineLength = maxLineLength + 2
        printWithBarEnd( defaultColor + defaultColor + " ______" + str(activities[0][0][1]) + " to " + str(activities[len(activities)-1][0][1]), maxLineLength, "_", " ")
        printWithBarEnd( defaultColor + defaultColor + "| ", maxLineLength)
        for line in lines:
            printWithBarEnd(line, maxLineLength)
        printWithBarEnd(defaultColor + defaultColor + "|", maxLineLength, "_")

def showAllActivityTypes():
    options = Options()
    printIfVerbose("0/4 opening page...")
    options.headless = True
    with webdriver.Firefox(options=options) as driver:
        wait = WebDriverWait(driver, 10)
        driver.get(getWebLoggerUrl())
        first_result = wait.until(presence_of_element_located((By.ID, "weeklyoverviewtable")))
        waitUntilMainPageIsFinished(driver)

        printIfVerbose("1/4 reading current layout...")
        # TODO, move page to the correct week
        activities = findCurrentLogs(str(driver.page_source))

        printIfVerbose("2/4 checking button...")

        columnActivitiesSize = 0
        for v in activities[0][1]:
            if len(v[0]) > 0:
                columnActivitiesSize = columnActivitiesSize + 1

        buttonXpath = '//*[@id="weeklyoverviewtable"]/tbody/tr[' + str(columnActivitiesSize + 2) + ']/td[' + str(1) + ']'
        button = driver.find_element_by_xpath(buttonXpath)
        button.click()

        printIfVerbose("3/4 opening submission page...")

        wait.until(presence_of_element_located((By.ID, "submitbuttonelement")))

        printIfVerbose("4/4 reading submission page...")

        allLines = str(driver.page_source).splitlines()
        relevantLines = []
        startSeen = False
        for x in allLines:
            if x.count('id="projectnameelement"') > 0:
                startSeen = True
            if x.count('id="projectnameelement_chzn"') > 0:
                break
            if startSeen:
                if x.count("<option ") == 0 and x.count("</option>") == 0 and len(x.strip()) > 0:
                    relevantLines.append(x.lstrip())

        for x in relevantLines:
            print(x)


def enterActivity(day, month, year, activity, duration, location):
    print("entering activity '" + activity + "' on '" + str(day) + "/" + str(month) + "/" + str(year) + "' for '" + str(duration) + "' days")
    options = Options()
    printIfVerbose("0/5 opening page...")
    options.headless = True
    with webdriver.Firefox(options=options) as driver:
        wait = WebDriverWait(driver, 10)
        driver.get(getWebLoggerUrl())
        first_result = wait.until(presence_of_element_located((By.ID, "weeklyoverviewtable")))
        waitUntilMainPageIsFinished(driver)

        printIfVerbose("1/5 reading current layout...")
        # TODO, move page to the correct week
        activities = findCurrentLogs(str(driver.page_source))

        printIfVerbose("2/5 checking button...")

        stringToMatch = (("0" + str(day))[:2]) + "/" + (("0" + str(month))[:2]) + "/" + str(year)
        column = -1
        for x in range(0, len(activities)):
            dayName = activities[x][0][0]
            dayDate = activities[x][0][1]
            if dayDate == stringToMatch:
                column = x
                break

        if column == -1:
            print("Cannot find column for date '" + stringToMatch + "'")
            return

        columnActivitiesSize = 0
        for v in activities[column][1]:
            if len(v[0]) > 0:
                columnActivitiesSize = columnActivitiesSize + 1

        buttonXpath = '//*[@id="weeklyoverviewtable"]/tbody/tr[' + str(columnActivitiesSize + 2) + ']/td[' + str(column+1) + ']'
        button = driver.find_element_by_xpath(buttonXpath)
        button.click()

        printIfVerbose("3/5 opening submission page...")

        wait.until(presence_of_element_located((By.ID, "submitbuttonelement")))

        printIfVerbose("4/5 filling info...")

        dropdown = driver.find_element_by_xpath('//*[@id="projectnameelement_chzn"]')
        dropdown.click()
        time.sleep(0.3)
        textbox = driver.find_element_by_xpath('//*[@id="projectnameelement_chzn"]/div/div/input')
        textbox.send_keys(activity)
        textbox.send_keys(Keys.RETURN)

        locationElement = driver.find_element_by_xpath('//*[@id="locationelement"]')
        locationElement.clear()
        locationElement.send_keys(location)

        durationElement = driver.find_element_by_xpath('//*[@id="durationelement"]')
        durationElement.clear()
        durationElement.send_keys(str(duration).replace(",", "."))

        printIfVerbose("5/5 submitting...")

        submitElement = driver.find_element_by_xpath('//*[@id="submitbuttonelement"]')
        time.sleep(0.5)
        submitElement.click()

        printIfVerbose("Done!")

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

def main_printActivitiesOfThisWeek():
    options = Options()
    options.headless = True
    with webdriver.Firefox(options=options) as driver:
        wait = WebDriverWait(driver, 10)
        driver.get(getWebLoggerUrl())
        first_result = wait.until(presence_of_element_located((By.ID, "weeklyoverviewtable")))
        waitUntilMainPageIsFinished(driver)

    #    print(driver.page_source)
        activities = findCurrentLogs(str(driver.page_source))
        printActivities(activities)

def main_enterActivity():
    date = [1, 1, 2000]
    activity = ""
    duration = 1.0
    location = "Delft"
    for arg in sys.argv:
        if arg.count("date=") > 0:
            dateStr = arg[arg.find("=")+1:]
            split = dateStr.split(" ")
            for x in range(0, 3):
                date[x] = int(split[x])
        if arg.count("activity=") > 0:
            activity = arg[arg.find("=")+1:]
        if arg.count("duration=") > 0:
            duration = float(arg[arg.find("=")+1:])
        if arg.count("location=") > 0:
            location = arg[arg.find("=")+1:]

    enterActivity(date[0], date[1], date[2], activity, duration, location)

if sys.argv.count("showThisWeek"):
    main_printActivitiesOfThisWeek()

if sys.argv.count("enterActivity"):
    main_enterActivity()

if sys.argv.count("showAllActivityTypes"):
    showAllActivityTypes()


#date="03 01 2020" activity=DED_SBI_IDLE duration=1.0

#getUserAndPass()

#    wait = WebDriverWait(driver, 10)
#    driver.get("https://google.com/ncr")
#    driver.find_element_by_name("q").send_keys("cheese" + Keys.RETURN)
#    print(first_result.get_attribute("textContent"))
