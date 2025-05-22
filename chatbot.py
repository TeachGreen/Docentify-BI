import pymysql
from sklearn.metrics.pairwise import cosine_similarity
from sentence_transformers import SentenceTransformer
from transformers import AutoTokenizer, TFAutoModelForSequenceClassification
import tensorflow as tf
from rapidfuzz import process
import spacy

# Carregar modelo spaCy para português
nlp = spacy.load("pt_core_news_sm")

def lematizar(texto):
    doc = nlp(texto.lower())
    return [token.lemma_ for token in doc if not token.is_punct and not token.is_space]

# Conexão com banco de dados
def connect_to_db(host, port, user, password, db_name):
    return pymysql.connect(host=host, port=port, user=user, password=password, database=db_name)

conn = connect_to_db('localhost', 3306, 'root', 'hanglose1', 'Docentify')

# Carregamento dos modelos
modelo_embeddings = SentenceTransformer("sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
modelo_bertimbau = TFAutoModelForSequenceClassification.from_pretrained("neuralmind/bert-base-portuguese-cased")
tokenizer_bertimbau = AutoTokenizer.from_pretrained("neuralmind/bert-base-portuguese-cased", truncation=True, max_length=512)

# Lista de intenções e embeddings
lista_intencoes = [
    "progresso",
    "tempo_conclusao",  
    "proximo_modulo",   
    "obrigatorios",     
    "duracao",          
    "cancelamento",     
    "atividades",       
    "alterar_email",    
    "instituicao",
    "certificado",
    "senha",
    "feedback",
    "suporte",
    "meus_cursos",      
    "conclusao"
]
intencoes_embeddings = modelo_embeddings.encode(lista_intencoes)

lemas_por_intencao_refinada = {
    "tempo_conclusao": [
        "tempo para terminar o curso", "quando termino", "quanto tempo falta",
        "tempo restante", "prazo final", "previsão de término", "tempo de conclusão"
    ],
    "progresso": [
        "progresso", "avanço", "andamento", "etapas", "evolução", "quanto já fiz",
        "como estou no curso", "minha evolução", "meu progresso", "meu andamento"
    ],
    "proximo_modulo": [
        "qual o próximo módulo", "qual vem depois", "etapa seguinte", "módulo seguinte",
        "lição seguinte", "seguir", "avançar", "próxima lição"
    ],
    "obrigatorios": [
        "cursos obrigatórios", "disciplinas obrigatórias", "requisito",
        "necessário", "precisa fazer", "obrigatório", "grade curricular"
    ],
    "duracao": [
        "duração do curso", "carga horária", "tempo total", "quantos dias tem",
        "tempo de curso", "quanto tempo leva"
    ],
    "cancelamento": [
        "cancelar", "cancelamento", "desistir", "remover inscrição",
        "encerrar matrícula", "excluir conta", "sair do curso", "quero cancelar"
    ],
    "atividades": [
        "atividade", "atividades pendentes", "exercício", "tarefa", "pendente",
        "lista de tarefas", "tarefas", "o que tenho que fazer", "o que falta fazer"
    ],
    "alterar_email": [
        "trocar email", "mudar email", "atualizar email", "editar email",
        "corrigir email", "alterar email", "meu email mudou"
    ],
    "instituicao": [
        "faculdade", "universidade", "instituição", "escola", "facens",
        "minha escola", "qual faculdade", "onde estudo"
    ],
    "certificado": [
        "certificado", "diploma", "comprovação", "emissão", "certificação",
        "comprovante", "documento de conclusão"
    ],
    "senha": [
        "senha", "esqueci", "resetar", "recuperar", "redefinir", "login",
        "acesso", "perdi a senha"
    ],
    "feedback": [
        "feedback", "opinião", "avaliar", "comentário", "avaliacao",
        "sugestão", "deixar avaliação", "dar opinião"
    ],
    "suporte": [
        "suporte", "ajuda", "atendimento", "contato", "assistência", "email do suporte",
        "problema técnico", "falar com suporte"
    ],
    
    "meus_cursos": [
        "matriculado", "inscrito", "inscrição", "meus estudos", "estou fazendo",
        "quais cursos", "meus cursos", "estou matriculado"
    ],
    "conclusao": [
        "finalizado", "completo", "concluído", "terminado", "fim de curso",
        "finalização", "concluir", "já finalizei"
    ]
}

def consultar_bd(query, params=None):
    with conn.cursor() as cursor:
        cursor.execute(query, params)
        return cursor.fetchall()

def buscar_dados_no_bd(usuario_id, intencao):
    if intencao == "instituicao":
        q = '''SELECT DISTINCT i.name FROM Institutions i
               JOIN Courses c ON i.id = c.institutionId
               JOIN Enrollments e ON e.courseId = c.id
               WHERE e.userId = %s'''
        r = consultar_bd(q, (usuario_id,))
        return ", ".join(x[0] for x in r) if r else "Nenhuma instituição encontrada."

    if intencao == "duracao":
        q = '''SELECT c.name, c.requiredTimeLimit FROM Courses c
               JOIN Enrollments e ON c.id = e.courseId
               WHERE e.userId = %s'''
        r = consultar_bd(q, (usuario_id,))
        return "Duração dos seus cursos:\n" + "\n".join(f"{x[0]}: {x[1]} dias" for x in r) if r else "Nenhum curso com duração definida foi encontrado."

    if intencao == "meus_cursos":
        q = '''SELECT c.name FROM Courses c
               JOIN Enrollments e ON c.id = e.courseId
               WHERE e.userId = %s'''
        r = consultar_bd(q, (usuario_id,))
        return "Cursos matriculados: " + ", ".join(x[0] for x in r) if r else "Você não está matriculado em nenhum curso."

    if intencao == "obrigatorios":
        q = '''SELECT c.name FROM Courses c
               JOIN Enrollments e ON c.id = e.courseId
               WHERE e.userId = %s AND c.isRequired = 1'''
        r = consultar_bd(q, (usuario_id,))
        return "Cursos obrigatórios:\n" + "\n".join(x[0] for x in r) if r else "Nenhum curso obrigatório encontrado."

    if intencao == "proximo_modulo":
        q = '''SELECT c.name, MAX(s.`order`) + 1 FROM Courses c
               JOIN Enrollments e ON c.id = e.courseId
               JOIN Steps s ON c.id = s.courseId
               JOIN UserProgress up ON up.enrollmentId = e.id AND up.stepId = s.id
               WHERE e.userId = %s GROUP BY c.name'''
        r = consultar_bd(q, (usuario_id,))
        return "\n".join(f"{x[0]}: próximo módulo {x[1]}" for x in r) if r else "Não foi possível identificar o próximo módulo."

    if intencao == "conclusao":
        q = '''SELECT c.name, COUNT(DISTINCT s.id), COUNT(DISTINCT up.stepId) FROM Courses c
               JOIN Enrollments e ON e.courseId = c.id
               JOIN Steps s ON s.courseId = c.id
               LEFT JOIN UserProgress up ON up.enrollmentId = e.id AND up.stepId = s.id
               WHERE e.userId = %s GROUP BY c.name'''
        r = consultar_bd(q, (usuario_id,))
        return "\n".join(f"{x[0]}: {x[2]}/{x[1]} etapas concluídas" for x in r) if r else "Nenhum progresso registrado."

    if intencao == "certificado":
        q = '''SELECT c.name FROM Courses c
               JOIN Enrollments e ON c.id = e.courseId
               WHERE e.userId = %s AND e.isActive = 1'''
        r = consultar_bd(q, (usuario_id,))
        return "Cursos com certificado: " + ", ".join(x[0] for x in r) if r else "Nenhum certificado disponível."

    if intencao == "progresso":
        q = '''SELECT c.name, COUNT(up.stepId) FROM UserProgress up
               JOIN Enrollments e ON up.enrollmentId = e.id
               JOIN Courses c ON e.courseId = c.id
               WHERE e.userId = %s
               GROUP BY c.name'''
        r = consultar_bd(q, (usuario_id,))
        return "\n".join(f"{x[0]}: {x[1]} etapas concluídas" for x in r) if r else "Você ainda não começou nenhum curso."

    respostas_fixas = {
        "suporte": "Entre em contato com suporte pelo email suporte@docentify.com",
        "feedback": "Você pode avaliar os cursos na seção 'Avaliações'.",
        "senha": "Caso tenha esquecido sua senha, redefina-a na página de login.",
        "alterar_email": "Para alterar seu email, acesse suas configurações de perfil.",
        "cancelamento": "Para cancelar sua matrícula, entre em contato com a instituição.",
        "atividades": "Acesse seu painel para ver atividades pendentes e concluídas.",
        "tempo_conclusao": "Você pode verificar sua previsão de conclusão do curso no seu painel de aluno." # Adicionando a resposta fixa para tempo_conclusao
    }
    return respostas_fixas.get(intencao, "Não encontrei informações relevantes para sua pergunta.")

def detectar_por_lematizacao_otimizado(texto, lista_intencoes, lemas_por_intencao):
    lemas = lematizar(texto)
    scores = {intencao: 0 for intencao in lista_intencoes}

    for intencao, lemas_alvo in lemas_por_intencao.items():
        pontuacao = 0
        for lema in lemas:
            if lema in lemas_alvo:
                pontuacao += 1
        # Normalizar a pontuação pelo número de lemas na pergunta
        if lemas:
            scores[intencao] = pontuacao / len(lemas)
        else:
            scores[intencao] = 0

    melhor_intencao = max(scores, key=scores.get)
    if scores[melhor_intencao] > 0.2:  
        return melhor_intencao
    return None

def corrigir_palavras(texto):
    palavras = texto.lower().split()
    for palavra in palavras:
        resultado = process.extractOne(palavra, lista_intencoes, score_cutoff=85) 
        if resultado:
            return resultado[0]
    return None

def buscar_intencao_com_embeddings(pergunta):
    pergunta_embed = modelo_embeddings.encode([pergunta])
    similaridade = cosine_similarity(pergunta_embed, intencoes_embeddings)
    if similaridade[0].max() < 0.65:
        return None
    return lista_intencoes[similaridade[0].argmax()]

def buscar_intencao_com_bertimbau(pergunta):
    inputs = tokenizer_bertimbau(pergunta, return_tensors="tf", truncation=True, padding=True, max_length=512)
    outputs = modelo_bertimbau(**inputs)
    pred = tf.argmax(outputs.logits, axis=-1).numpy()[0]
    prob = tf.nn.softmax(outputs.logits, axis=-1).numpy()[0][pred]
    return lista_intencoes[pred] if prob > 0.7 else None

def prever_intencao(pergunta, usuario_id):
    tentativas = 0
    while tentativas < 3:
        intencao = detectar_por_lematizacao_otimizado(pergunta, lista_intencoes, lemas_por_intencao_refinada)
        if not intencao:
            intencao = corrigir_palavras(pergunta)
        if not intencao:
            intencao = buscar_intencao_com_embeddings(pergunta)
        if not intencao:
            intencao = buscar_intencao_com_bertimbau(pergunta)
        if intencao:
            return buscar_dados_no_bd(usuario_id, intencao) if intencao not in respostas_fixas else respostas_fixas[intencao]
        print("chatbot: Não entendi sua pergunta. Pode repetir, por favor?")
        pergunta = input("Usuário: ")
        tentativas += 1
    print('\nchatbot: Infelizmente não consegui entender sua solicitação.\nMas fique tranquilo que o nosso suporte poderá lhe ajudar através do email\n---> docentify@gmail.com <---')
    exit()

def validar_usuario():
    tentativas = 0
    while tentativas < 3:
        email = input('\nOlá, Me chamo IPÊ e sou seu assistente virtual.\nPara que possamos começar, por favor, informe seu e-mail:\n')
        query = "SELECT id, name FROM Users WHERE email = %s"
        usuario = consultar_bd(query, (email,))
        if usuario:
            usuario_id, nome = usuario[0]
            print(f"chatbot: Olá {nome}, no que posso lhe ajudar hoje?")
            return usuario_id, nome
        else:
            tentativas += 1
            print(f"E-mail não encontrado. Tentativas restantes: {3 - tentativas}")
    print('\nchatbot: Infelizmente após 3 tentativas não conseguimos achar seu cadastro.\nMas fique tranquilo que o nosso suporte poderá lhe ajudar através do email\n---> docentify@gmail.com <---')
    exit()

# Execução principal
usuario_id, nome = validar_usuario()

respostas_fixas = {
    "suporte": "Entre em contato com suporte pelo email suporte@docentify.com",
    "feedback": "Você pode avaliar os cursos na seção 'Avaliações'.",
    "senha": "Caso tenha esquecido sua senha, redefina-a na página de login.",
    "alterar_email": "Para alterar seu email, acesse suas configurações de perfil.",
    "cancelamento": "Para cancelar sua matrícula, entre em contato com a instituição.",
    "atividades": "Acesse seu painel para ver atividades pendentes e concluídas.",
    "tempo_conclusao": "Você pode verificar sua previsão de conclusão do curso no seu painel de aluno."
}

while True:
    entrada = input("usuário: ")
    if entrada.lower() == "sair":
        print("chatbot: Foi um prazer conversar com você. Até logo!")
        break
    resposta = prever_intencao(entrada, usuario_id)
    print(f"chatbot: {resposta}")