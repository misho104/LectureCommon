# Similarity calculators using various models

# Use cases are:
#   transformer(sentences, "all-mpnet-base-v2")
#   transformer(sentences, "all-MiniLM-L6-v2")
#   idf(sentences, stop_words="english", ngram_range=(1,3))
#   idf(sentences)
#   spacy_sim(sentences)
#   spacy_ngram(sentences)

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


class ModelCache:
    def __init__(self):
        self._models = {}

    def __getitem__(self, key: str):
        # lazy import
        if key not in self._models:
            if key == "all-mpnet-base-v2":
                from sentence_transformers import SentenceTransformer

                self._models[key] = SentenceTransformer("all-mpnet-base-v2")
            elif key == "all-MiniLM-L6-v2":
                from sentence_transformers import SentenceTransformer

                self._models[key] = SentenceTransformer("all-MiniLM-L6-v2")
            elif key == "en_core_web_lg":
                import spacy

                self._models[key] = spacy.load("en_core_web_lg")
            else:
                raise ValueError(f"Unknown model: {key}")
        return self._models[key]


models = ModelCache()


def transformer(sentences, model="all-mpnet-base-v2"):
    m = models[model]
    embeddings = m.encode(sentences)
    return m.similarity(embeddings, embeddings)


def idf(sentences, **kwargs) -> list[list[float]]:
    vectorizer = TfidfVectorizer(lowercase=True, **kwargs)
    vectors = vectorizer.fit_transform(sentences).toarray()
    matrix = cosine_similarity(vectors)
    filter_matrix(sentences, matrix)
    return matrix


def spacy_sim(sentences) -> list[list[float]]:
    docs = [models["en_core_web_lg"](sentence) for sentence in sentences]
    result = [[1 for _ in sentences] for _ in sentences]  # type: list[list[float]]
    for i, x in enumerate(docs):
        for j, y in enumerate(docs):
            if i > j:
                result[i][j] = result[j][i] = x.similarity(y)
    return result


def spacy_ngram(sentences) -> list[list[float]]:
    def get_ngrams(sentence, n=3):
        doc = models["en_core_web_lg"](sentence)
        tokens = [token.text.lower() for token in doc if token.is_alpha]
        return (
            set(zip(*[tokens[i:] for i in range(n)], strict=False))
            if len(tokens) >= n
            else set()
        )

    docs = [get_ngrams(sentence) for sentence in sentences]
    result = [[1 for _ in sentences] for _ in sentences]  # type: list[list[float]]
    for i, x in enumerate(docs):
        for j, y in enumerate(docs):
            if i > j:
                result[i][j] = result[j][i] = len(x & y) / max(len(x), len(y))
    return result


def filter_matrix(sentences, matrix):
    for i, sentence in enumerate(sentences):
        if len(sentence) < 20:
            for j in range(len(sentences)):
                matrix[i][j] = matrix[j][i] = -1


def parse_matrices(
    *args: list[list[float]],
) -> list[tuple[int, int, float, list[float]]]:
    result = []
    n = len(args[0])
    for matrix in args:
        assert len(matrix) == n
        assert all(len(row) == n for row in matrix)
    for i in range(n):
        for j in range(i + 1, n):
            array = [matrix[i][j] for matrix in args]
            result.append((i, j, max(array), array))
    result.sort(key=lambda x: x[2], reverse=True)
    return result


def format_s(v: float | None) -> str:
    if v is None or v < 0:
        return "\033[90m---\033[0m"
    elif v < 0.6:
        return f"{v:.2f}"
    elif v < 0.8:
        return f"\033[92m{v:.2f}\033[0m"
    elif v < 0.9:
        return f"\033[93m{v:.2f}\033[0m"
    else:
        return f"\033[91m{v:.2f}\033[0m"


def flatten_matrices(
    *matrices: list[list[float]], shift: int = 0, nor: list[int] | None = None
) -> dict[tuple[int, int], tuple[float, list[float]]]:
    n = len(matrices[0])
    for matrix in matrices:
        assert len(matrix) == n
        assert all(len(row) == n for row in matrix)

    result = {}
    for n, matrix in enumerate(matrices):
        for i, row in enumerate(matrix):
            for j, value in enumerate(row):
                i2 = i + shift
                j2 = j + shift
                if i2 < j2 and (nor is None or (i2 not in nor and j2 not in nor)):
                    if n == 0:
                        result[(i2, j2)] = (value, [value])
                    else:
                        result[(i2, j2)][1].append(value)
                        if value > result[(i2, j2)][0]:
                            result[(i2, j2)] = (value, result[(i2, j2)][1])
    return result


def print_similarity(
    flatten: dict[tuple[int, int], tuple[float, list[float]]], threshold=0.8
) -> None:
    at_least = 10
    result = [(sim, i, j, array) for (i, j), (sim, array) in flatten.items()]
    result.sort()
    threshold = min(result[-at_least][0], threshold) if len(result) >= at_least else 0
    for sim, i, j, array in sorted(result):
        if sim >= threshold:
            print(f"{i:2d} {j:2d}\t", end="")
            for t in array:
                print(f"{format_s(t)}\t", end="")
            print("")
