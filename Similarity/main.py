import json
import logging
import re

import click
import coloredlogs
import gspread
import pandas as pd
from google.oauth2.service_account import Credentials

import comparator

CREDENTIAL = "credential.json"
KEYS = "keys.json"
SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive",
]
TABLE_ADDITIONAL_KEYS = [
    ["ID", "Name", "SK"],  # before SIM
    ["Evaluation", "Score"],  # after SIM
]

TABLE_REGEXPS = {
    re.compile(r"タイムスタンプ"): "ignore",
    re.compile(r"メールアドレス"): "ignore",
    re.compile(r"^Write your Student ID"): "ID",
    re.compile(r"secret keyword", re.I): "ignore",
    re.compile(r"^Sim\d+"): "ignore",
    re.compile(r"^SC$"): "ignore",
    re.compile(r"^Bare$"): "ignore",
    re.compile(r"列"): "ignore",
}

coloredlogs.install(
    level=logging.INFO,
    logger=logging.getLogger(),
    fmt="log: %(levelname)8s %(message)s",
)


def get_client() -> gspread.Client:
    auth = Credentials.from_service_account_file(CREDENTIAL, scopes=SCOPES)
    client = gspread.authorize(auth)
    return client


def get_data(client: gspread.Client, file_id: str, tab_name: str) -> pd.DataFrame:
    file = client.open_by_key(file_id)
    tab = file.worksheet(tab_name)
    data = tab.get_all_values()
    df = pd.DataFrame(data[1:], columns=data[0])
    return df


def save_data(
    client: gspread.Client, file_id: str, tab_name: str, df: pd.DataFrame
) -> None:
    file = client.open_by_key(file_id)
    tab = file.add_worksheet(title=tab_name, rows=100, cols=52)
    data = [df.columns.tolist()] + df.values.tolist()
    tab.update("A1", data)
    return df


def check_similarity(
    df: pd.DataFrame,
    noc: list[int] | None = None,
    nor: list[int] | None = None,
    row_shift: int = 0,
) -> None:
    """
    Check each key in the DataFrame and find the columns to be evaluated.
    """
    for key in TABLE_ADDITIONAL_KEYS[0]:
        if key not in df.columns:
            df[key] = None

    keys_to_evaluate = []
    for col in df.columns:
        if col in TABLE_ADDITIONAL_KEYS[0] or col in TABLE_ADDITIONAL_KEYS[1]:
            continue
        to_evaluate = True
        for pattern, key in TABLE_REGEXPS.items():
            if pattern.search(col):
                to_evaluate = False
                if key == "ignore":
                    break
                else:
                    df[key] = df[col]
                    break
        if to_evaluate:
            keys_to_evaluate.append(col)

    for n in sorted(noc or [], reverse=True):
        del keys_to_evaluate[n]
    print("Keys to evaluate:")
    [print(f"\t{k}") for k in keys_to_evaluate]

    matrices = [
        comparator.idf(df[key].to_list(), ngram_range=(2, 3))
        for key in keys_to_evaluate
    ]
    logging.info(f"Matrix flatten by Row Shift {row_shift} and Ignored Rows {nor}.")
    flatten = comparator.flatten_matrices(*matrices, shift=row_shift, nor=nor)
    comparator.print_similarity(flatten)


@click.command()
@click.argument("table")
@click.option("--noc", help="Columns to be ignored.")
@click.option("--nor", help="Rows to be ignored.")
@click.option("--row-shift", default=2, help="Index of first row.")
def similarity(table, noc, nor, row_shift):
    with open(KEYS) as f:
        setting = json.load(f)
    if m := re.match(r"(\w+):(.+)", table):
        try:
            table_key = setting["sheetId"][m.group(1)], m.group(2)
            client = get_client()
            df = get_data(client, *table_key)
        except gspread.exceptions.WorksheetNotFound:
            logging.error(f"Sheet {m.group(2)} not found in {m.group(1)}.")
            exit(1)
    else:
        click.BadParameter("Invalid table_key", param=table)
    noc_list = [int(i) for i in noc.split(",")] if noc else []
    nor_list = [int(i) for i in nor.split(",")] if nor else []
    check_similarity(df, noc=noc_list, nor=nor_list, row_shift=row_shift)


if __name__ == "__main__":
    similarity()
# hoge = 1
# if hoge == 0 and __name__ == "__main__":
#     with open(KEYS, "r") as f:
#         setting = json.load(f)
#     client = get_client()
#     df = get_data(client, setting["sheetId"], "C05")
#     df.to_pickle("output.pkl")
#
# if hoge == 1 and __name__ == "__main__":
#     df = pd.read_pickle("output.pkl")
#     df2 = parse_data(df)
#     exit(0)
#     pd.set_option("display.max_columns", None)
#     print(df2)
#     with open(KEYS, "r") as f:
#         setting = json.load(f)
#     # save_data(get_client(), setting["sheetId"], "new", df2)
#     # save_data(get_client(), setting["sheetId"], "new", df2)
