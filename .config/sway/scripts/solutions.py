import re

def paper_to_solution(question):
    match_obj = re.search(r"^.*\/y(?P<year>\d{4})p(?P<paper>\d+)q(?P<question>\d+)\.pdf$", question)

    if match_obj is None:
        return question

    year = match_obj.group('year').zfill(4)
    paper = match_obj.group('paper').zfill(2)
    question = match_obj.group('question').zfill(2)

    solution_str = f"https://www.cl.cam.ac.uk/teaching/exams/solutions/{year}/{year}-p{paper}-q{question}-solutions.pdf"
    return solution_str

def solution_to_paper(solution):
    match_obj = re.search(r"^.*/(?P<year>\d{4})-p(?P<paper>\d{2})-q(?P<question>\d{2})-solutions\.pdf$", solution)

    if match_obj is None:
        return solution

    year = match_obj.group('year').lstrip("0")
    paper = match_obj.group('paper').lstrip("0")    
    question = match_obj.group('question').lstrip("0")

    question_str = f"https://www.cl.cam.ac.uk/teaching/exams/pastpapers/y{year}p{paper}q{question}.pdf"
    return question_str

def toggle(string):
    paper = solution_to_paper(string)
    solution = paper_to_solution(string)

    if paper == string:
        return solution
    else:
        return paper

print(toggle(input()))
