# Go2Backstage

Go2Backstage é uma plataforma de networking e marketplace para profissionais freelancers da indústria de eventos e produções. O objetivo é conectar técnicos, produtores e outros especialistas a contratantes que buscam serviços para shows, festivais e eventos corporativos.

Este repositório contém o esquema de banco de dados e documentos básicos de design para iniciar a aplicação.

## Design System
- **Cor de destaque:** `#39FF14` (verde vibrante)
- **Fonte:** sans-serif moderna (ex. Inter ou Poppins)
- **Layout:** mobile-first
- **Status online/offline:** `#00C853` / `#BDBDBD`

## Estrutura do Banco de Dados
O arquivo [`database/schema.sql`](database/schema.sql) contém todo o esquema SQL compatível com Supabase:
- Tabelas `users`, `jobs`, `applications`, `messages`
- Políticas de segurança (RLS) para garantir que cada usuário só consiga alterar seus próprios dados
- Triggers para criar perfis automaticamente e atualizar timestamps

Para aplicar o schema em um projeto Supabase:
1. Crie um projeto no painel do Supabase
2. Acesse a aba SQL Editor e execute o conteúdo do arquivo [`schema.sql`](database/schema.sql)
3. Ajuste as políticas de RLS se necessário e habilite autenticação por e‑mail/senha

## Próximos Passos
Este repositório não possui ainda o frontend. Para criar a aplicação você pode utilizar frameworks web ou mobile de sua preferência (React, Next.js, Expo, etc.) seguindo o layout descrito acima. As principais telas sugeridas são:

1. **Cadastro de Conta**
2. **Home**
3. **Explorar Profissionais**
4. **Perfil do Profissional**
5. **Feed de Jobs**
6. **Postar Job**
7. **Mensagens**
8. **Painel do Profissional**

Sinta‑se livre para contribuir com implementações ou abrir issues para dúvidas.
