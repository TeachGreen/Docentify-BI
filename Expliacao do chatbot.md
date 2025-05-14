## Organização do Chatbot com Detecção de Intenção

### Camadas de Detecção

1. **Lematização com spaCy**  
   Primeira camada. Reduz as palavras à sua forma base (ex: *terminar* → *terminar*, *terminando*, *terminei*), facilitando o reconhecimento da intenção, mesmo com variações.

2. **RapidFuzz (Fuzzy Matching)**  
   Segunda camada. Aplica correspondência por similaridade para corrigir erros de digitação ou variações, tentando mapear diretamente com uma intenção existente.

3. **Embeddings com SentenceTransformer**  
   Terceira camada. Analisa o significado da frase com vetores semânticos. Identifica a intenção mesmo que a frase use palavras diferentes.

4. **Classificação com BERTimbau**  
   Quarta camada. Usa um modelo de linguagem treinado para compreender o contexto e classificar a intenção com base no que aprendeu.

5. **Fallback (Camada Especialista)**  
   Se nenhuma camada entender a frase após 3 tentativas, o chatbot redireciona o usuário para o suporte humano.

---

### Contexto Geral do Chat

O chatbot é projetado para ser **preciso, tolerante a erros e eficiente**. Ele tenta entender a intenção do usuário passando por camadas de análise, da mais simples à mais sofisticada. Se não conseguir, encaminha para o suporte. Isso garante **boa usabilidade**, mesmo com frases mal formuladas.
