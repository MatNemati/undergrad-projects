from cmath import inf
from tkinter import *
from tkinter import ttk
from tkcalendar import DateEntry
from datetime import date, datetime
import os

data_list = list()


def adddata(event):
    "Adding input data to database"
    ID = len(data_list) + 1
    while True:
        description = d_entry.get()
        if len(description) == 0:
            d_entry.delete(0, END)
            d_error_label.config(text="Description can not be empty")
            d_entry.focus()
            return None
        elif "^" in description:
            d_error_label.config(
                text="Description can not contain '^' character")
            d_entry.focus()
            return None
        else:
            d_error_label.config(text="")
            break
    while True:
        try:
            price = float(p_entry.get())
            if price < 0:
                p_entry.delete(0, END)
                p_error_label.config(text="Price must be a positive number")
                p_entry.focus()
                return None
            p_error_label.config(text="")
            break
        except:
            p_entry.delete(0, END)
            p_error_label.config(text="Price must be a number")
            p_entry.focus()
            return None
    input_date = date_entry.get()
    data = [ID, description, price, input_date]
    tree.insert("", "end", values=data)
    d_entry.delete(0, END)
    p_entry.delete(0, END)
    d_entry.focus()
    data_list.append([ID, description, price, input_date])
    print([ID, description, price, input_date])
    with open("DB.txt", 'a', encoding="utf-8") as f:
        f.write(f"{ID}^ {description}^ {price}^ {input_date}\n")


def deletedatabase():
    try:
        os.remove("DB.txt")
    except OSError:
        pass
    # https://stackoverflow.com/q/22812134/11954834
    tree.delete(*tree.get_children())


def filterdata():
    while True:
        try:
            min_price = float(
                p_min_entry.get()) if p_min_entry.get() != "" else 0
            if min_price < 0:
                p_min_entry.delete(0, END)
                p_min_error_label.config(
                    text="Price must be a positive number")
                p_min_entry.focus()
                return None
            p_min_error_label.config(text="")
            break
        except:
            p_min_entry.delete(0, END)
            p_min_error_label.config(text="Price must be a number")
            p_min_entry.focus()
            return None
    while True:
        try:
            max_price = float(
                p_max_entry.get()) if p_max_entry.get() != "" else inf
            if max_price < 0:
                p_max_entry.delete(0, END)
                p_max_error_label.config(
                    text="Price must be a positive number")
                p_max_entry.focus()
                return None
            p_max_error_label.config(text="")
            break
        except:
            p_max_entry.delete(0, END)
            p_max_error_label.config(text="Price must be a number")
            p_max_entry.focus()
            return None
    start_date = str(start_date_entry.get())[:10]
    finish_date = str(finish_date_entry.get())[:10]
    start_date = datetime.strptime(start_date, '%Y/%m/%d')
    finish_date = datetime.strptime(finish_date, '%Y/%m/%d')
    tree.delete(*tree.get_children())
    for i in data_list:

        a, b, c, d = i
        d = d.strip()
        # Converting str to date object https://stackoverflow.com/q/20365854/11954834
        d = datetime.strptime(d, '%Y/%m/%d')
        z = min_price <= float(c)
        y = float(c) <= max_price
        x = start_date <= d
        w = d <= finish_date
        if (z and y) and (x and w):
            data = [a, b, c, str(d)[:10]]
            tree.insert("", "end", values=data)


def resetfilter():
    tree.delete(*tree.get_children())
    fetchdata()


def fetchdata():
    try:
        with open("DB.txt", 'r', encoding="utf-8") as f:
            for line in f.readlines():
                try:
                    idx, description, price, date = line.split("^")
                    data = [idx, description, price, date]
                    tree.insert("", "end", values=data)
                    data_list.append(data)
                except:
                    pass
    except:
        pass


window = Tk()
window.title("Financial Record")
window.geometry("550x700")

# Adding white gray Hex color to backround
window.configure(background="#D6D5CB")

# --------------- Table
HEADINGS = ["ID", "Description", "Price", "Date"]  # Constants
tree = ttk.Treeview(master=window, column=HEADINGS,
                    show="headings", height=8)
for i in HEADINGS:
    tree.heading(i, text=i)
    if i == "ID":
        tree.column(i, width=50, stretch=NO, anchor=CENTER)
    elif i == "Description":
        tree.column(i, width=200, stretch=NO, anchor=CENTER)
    elif i == "Price":
        tree.column(i, width=150, stretch=NO, anchor=CENTER)
    elif i == "Date":
        tree.column(i, width=140, stretch=NO, anchor=CENTER)
tree.grid(row=4, column=0, padx=2, pady=5, columnspan=5)


# scrollbars https://stackoverflow.com/q/41877848/11954834
vsb = Scrollbar(window, orient="vertical", command=tree.yview)
vsb.place(relx=0.978, rely=0.332, relheight=0.267, relwidth=0.020)

hsb = Scrollbar(window, orient="horizontal", command=tree.xview)
hsb.place(relx=0.014, rely=0.597, relheight=0.020, relwidth=0.986)
tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)
fetchdata()  # Update table with database at start.

# -------------- Description
d_label = Label(master=window, text="Description")
d_label.grid(row=0, column=0, padx=20, pady=20)
d_entry = Entry(master=window)
d_entry.grid(row=0, column=1, padx=20, pady=20)

d_error_label = Label(master=window, text="",
                      background="#D6D5CB", foreground="red")
d_error_label.grid(row=0, column=2, padx=5, pady=20)
# -------------- Price
p_label = Label(master=window, text="Price")
p_label.grid(row=1, column=0, padx=20, pady=20)
p_entry = Entry(master=window)
p_entry.grid(row=1, column=1, padx=20, pady=20)

p_error_label = Label(master=window, text="",
                      background="#D6D5CB", foreground="red")
p_error_label.grid(row=1, column=2, padx=5, pady=20)


# -------------- Add date
date_label = Label(master=window, text="Date")
date_label.grid(row=2, column=0, padx=20, pady=20)

dt = date.today()  # today, limit the date range till today
date_entry = DateEntry(master=window, date_pattern='yyyy/mm/dd',
                       background="gray", foreground="white", maxdate=dt)
date_entry.grid(row=2, column=1, padx=20, pady=20)

# -------------- Add data button
add_data = Button(master=window, text="Add", width=12)
add_data.grid(row=3, column=1)
add_data.bind("<Button-1>", adddata)

# -------------- Delete database button
add_data = Button(master=window, text="Clear database!",
                  width=12, foreground="red", command=deletedatabase)
add_data.grid(row=10, column=2)

# -------------- search section -------------- #
p_min_label = Label(master=window, text="Minimum Price")
p_min_label.grid(row=5, column=0, padx=20, pady=15)
p_min_error_label = Label(master=window, text="",
                          background="#D6D5CB", foreground="red")
p_min_error_label.grid(row=5, column=2, padx=2, pady=15)
p_min_entry = Entry(master=window)
p_min_entry.grid(row=5, column=1, padx=20, pady=5)

p_max_label = Label(master=window, text="Maximum Price")
p_max_label.grid(row=6, column=0, padx=20, pady=5)
p_max_error_label = Label(master=window, text="",
                          background="#D6D5CB", foreground="red")
p_max_error_label.grid(row=5, column=2, padx=2, pady=5)
p_max_entry = Entry(master=window)
p_max_entry.grid(row=6, column=1, padx=20, pady=5)

start_date_label = Label(master=window, text="Start Date")
start_date_label.grid(row=7, column=0, padx=20, pady=15)
start_date_entry = DateEntry(master=window, date_pattern='yyyy/mm/dd',
                             background="gray", foreground="white", maxdate=dt)
start_date_entry.grid(row=7, column=1, padx=20, pady=15)
finish_date_label = Label(master=window, text="Finish Date")
finish_date_label.grid(row=8, column=0, padx=20, pady=5)
finish_date_entry = DateEntry(master=window, date_pattern='yyyy/mm/dd',
                              background="gray", foreground="white", maxdate=dt)
finish_date_entry.grid(row=8, column=1, padx=20, pady=5)

# -------------- Add filter button
add_data = Button(master=window, text="Filter",
                  width=12, command=filterdata)
add_data.grid(row=9, column=1, pady=5)

# -------------- Add reset filter button
add_data = Button(master=window, text="Reset Filter",
                  width=12, command=resetfilter)
add_data.grid(row=10, column=1, pady=5)

# Prevent to resize the program.
window.resizable(False, False)
window.mainloop()
