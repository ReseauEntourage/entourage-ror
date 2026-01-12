require 'anthropic'

module ClaudeServices
  class CodeAnalyzer
    MAX_ITERATIONS = 5
    MAX_FILES_PER_ITERATION = 5
    
    SYSTEM_PROMPT = <<~PROMPT
      Tu es un agent d'analyse de code expert en Ruby on Rails. Tu as accès à la codebase complète d'un projet Rails 7.
      
      Tu dois analyser le code de manière approfondie pour répondre aux questions des développeurs.
      
      IMPORTANT : Les questions seront posées en français, mais le code est en anglais. Tu dois faire le lien entre les concepts français et les noms de variables/classes/méthodes en anglais.
      
      Tu as accès aux outils suivants :
      
      1. **list_files** : Liste tous les fichiers d'un répertoire
         Paramètres : { "directory": "app/models" }
      
      2. **read_file** : Lit le contenu d'un fichier
         Paramètres : { "file_path": "app/models/user.rb" }
      
      3. **search_in_codebase** : Recherche un pattern dans tout le code
         Paramètres : { "pattern": "def authenticate", "file_types": [".rb"] }
      
      4. **analyze_dependencies** : Analyse les dépendances d'une classe/fichier
         Paramètres : { "file_path": "app/models/user.rb" }
      
      5. **grep_codebase** : Recherche avancée avec regex dans le code
         Paramètres : { "regex": "class.*Controller", "directory": "app/controllers" }
      
      PROCESSUS D'ANALYSE :
      
      1. Analyse d'abord la question pour comprendre ce qui est demandé
      2. Détermine quelle partie de la codebase examiner en premier
      3. Utilise les outils pour explorer le code de manière itérative
      4. Approfondis ton analyse en fonction de ce que tu découvres
      5. Une fois que tu as toutes les informations, fournis une réponse complète
      
      Pour répondre, tu DOIS utiliser ce format XML :
      
      <thinking>
      Explique ton raisonnement et ce que tu comptes faire
      </thinking>
      
      <tool_use>
      <tool_name>nom_de_l_outil</tool_name>
      <parameters>
      {"param": "value"}
      </parameters>
      </tool_use>
      
      OU si tu as terminé ton analyse :
      
      <answer>
      Ta réponse finale détaillée en français en moins de 200 mots
      </answer>
      
      N'hésite pas à utiliser plusieurs outils successivement avant de donner ta réponse finale.
    PROMPT

    def initialize(question, project_root: Rails.root)
      @question = question
      @project_root = project_root
      @client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])
      @conversation_history = []
      @files_examined = []
      @iteration_count = 0
    end

    def analyze
      Rails.logger.info("🤖 Starting agentic analysis for: #{@question}")
      
      # Construire le contexte initial
      initial_context = build_initial_context
      
      # Démarrer la conversation
      add_user_message(<<~MSG)
        Voici la structure du projet Rails :
        
        #{initial_context}
        
        Question de l'utilisateur : #{@question}
        
        Commence ton analyse. Utilise les outils dont tu as besoin pour explorer le code et répondre précisément.
      MSG
      
      # Boucle agentic : Claude décide quels outils utiliser
      loop do
        @iteration_count += 1
        
        if @iteration_count > MAX_ITERATIONS
          Rails.logger.warn("⚠️ Max iterations reached")
          break
        end
        
        # Appeler Claude
        response = call_claude
        
        # Parser la réponse
        parsed = parse_response(response)
        
        if parsed[:type] == :answer
          # Claude a terminé son analyse
          return {
            success: true,
            answer: parsed[:content],
            files_examined: @files_examined.uniq,
            iterations: @iteration_count
          }
        elsif parsed[:type] == :tool_use
          # Claude veut utiliser un outil
          tool_result = execute_tool(parsed[:tool_name], parsed[:parameters])
          
          # Ajouter le résultat à l'historique
          add_assistant_message(response)
          add_user_message("Résultat de l'outil #{parsed[:tool_name]} :\n\n#{tool_result}")
        else
          Rails.logger.error("❌ Unable to parse Claude's response")
          break
        end
      end
      
      # Fallback si la boucle se termine sans réponse
      {
        success: false,
        error: "L'analyse n'a pas pu être complétée dans le nombre d'itérations autorisé",
        files_examined: @files_examined.uniq,
        iterations: @iteration_count
      }
    rescue StandardError => e
      Rails.logger.error("❌ AgenticCodeAnalyzer Error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      {
        success: false,
        error: e.message
      }
    end

    private

    def build_initial_context
      # Fournir une carte de la structure du projet
      structure = []
      
      %w[app/models app/controllers app/services app/jobs config lib].each do |dir|
        path = @project_root.join(dir)
        next unless Dir.exist?(path)
        
        structure << "\n📁 #{dir}/"
        Dir.glob(path.join("**/*.rb")).take(20).each do |file|
          relative = file.sub("#{@project_root}/", "")
          structure << "   #{relative}"
        end
      end
      
      # Ajouter schema.rb
      schema_path = @project_root.join("db/schema.rb")
      if File.exist?(schema_path)
        structure << "\n📁 db/"
        structure << "   db/schema.rb"
      end
      
      structure.join("\n")
    end

    def call_claude
      response = @client.messages(
        parameters: {
          model: "claude-sonnet-4-20250514",
          max_tokens: 4000,
          system: SYSTEM_PROMPT,
          messages: @conversation_history
        }
      )

      response.dig("content", 0, "text") || ""
    end

    def parse_response(response)
      # Parser les balises XML de la réponse
      if response =~ /<answer>(.*?)<\/answer>/m
        { type: :answer, content: $1.strip }
      elsif response =~ /<tool_name>(.*?)<\/tool_name>/m
        tool_name = $1.strip
        
        params_match = response.match(/<parameters>(.*?)<\/parameters>/m)
        parameters = params_match ? JSON.parse(params_match[1].strip) : {}
        
        { type: :tool_use, tool_name: tool_name, parameters: parameters }
      else
        # Tentative de détecter si c'est une réponse finale sans balises
        if response.match?(/en (conclusion|résumé|bref)|pour répondre|la réponse est/i) && @iteration_count >= 2
          { type: :answer, content: response }
        else
          { type: :unknown, content: response }
        end
      end
    end

    def execute_tool(tool_name, parameters)
      Rails.logger.info("🔧 Executing tool: #{tool_name} with params: #{parameters}")
      
      case tool_name
      when "list_files"
        list_files(parameters["directory"])
      when "read_file"
        read_file(parameters["file_path"])
      when "search_in_codebase"
        search_in_codebase(parameters["pattern"], parameters["file_types"])
      when "analyze_dependencies"
        analyze_dependencies(parameters["file_path"])
      when "grep_codebase"
        grep_codebase(parameters["regex"], parameters["directory"])
      else
        "❌ Outil inconnu : #{tool_name}"
      end
    rescue StandardError => e
      "❌ Erreur lors de l'exécution de l'outil : #{e.message}"
    end

    # === IMPLÉMENTATION DES OUTILS ===

    def list_files(directory)
      dir_path = @project_root.join(directory)
      return "❌ Répertoire inexistant : #{directory}" unless Dir.exist?(dir_path)
      
      files = Dir.glob(dir_path.join("**/*.rb"))
        .map { |f| f.sub("#{@project_root}/", "") }
        .take(50)
      
      "📁 Fichiers dans #{directory} :\n#{files.join("\n")}"
    end

    def read_file(file_path)
      full_path = @project_root.join(file_path)
      return "❌ Fichier inexistant : #{file_path}" unless File.exist?(full_path)
      
      @files_examined << file_path
      
      content = File.read(full_path)
      "📄 Contenu de #{file_path} :\n\n```ruby\n#{content}\n```"
    end

    def search_in_codebase(pattern, file_types = [".rb"])
      results = []
      
      file_types.each do |ext|
        Dir.glob(@project_root.join("**/*#{ext}")).each do |file|
          next unless File.file?(file)
          
          content = File.read(file)
          if content.include?(pattern)
            relative = file.sub("#{@project_root}/", "")
            # Extraire les lignes pertinentes
            lines = content.lines.each_with_index.select { |line, _| line.include?(pattern) }
            results << "#{relative}:\n" + lines.map { |line, idx| "  L#{idx + 1}: #{line.strip}" }.join("\n")
          end
          
          break if results.size >= 10
        end
      end
      
      if results.empty?
        "❌ Aucun résultat pour le pattern : #{pattern}"
      else
        "🔍 Résultats pour '#{pattern}' :\n\n#{results.join("\n\n")}"
      end
    end

    def analyze_dependencies(file_path)
      full_path = @project_root.join(file_path)
      return "❌ Fichier inexistant : #{file_path}" unless File.exist?(full_path)
      
      @files_examined << file_path
      content = File.read(full_path)
      
      dependencies = {
        requires: [],
        includes: [],
        extends: [],
        associations: [],
        uses: []
      }
      
      # Extraire les requires
      content.scan(/require\s+['"](.+?)['"]/) { dependencies[:requires] << $1 }
      
      # Extraire les includes/extends
      content.scan(/include\s+(\w+)/) { dependencies[:includes] << $1 }
      content.scan(/extend\s+(\w+)/) { dependencies[:extends] << $1 }
      
      # Extraire les associations Rails
      content.scan(/(has_many|has_one|belongs_to|has_and_belongs_to_many)\s+:(\w+)/) do
        dependencies[:associations] << "#{$1} :#{$2}"
      end
      
      # Extraire les références à d'autres classes
      content.scan(/(\w+)\.(?:new|find|where|all|create)/) { dependencies[:uses] << $1 }
      
      result = "🔗 Dépendances de #{file_path} :\n\n"
      dependencies.each do |type, items|
        next if items.empty?
        result += "#{type.to_s.capitalize} : #{items.uniq.join(', ')}\n"
      end
      
      result
    end

    def grep_codebase(regex, directory = "app")
      dir_path = @project_root.join(directory)
      return "❌ Répertoire inexistant : #{directory}" unless Dir.exist?(dir_path)
      
      results = []
      pattern = Regexp.new(regex)
      
      Dir.glob(dir_path.join("**/*.rb")).each do |file|
        content = File.read(file)
        matches = content.scan(pattern)
        
        if matches.any?
          relative = file.sub("#{@project_root}/", "")
          results << "#{relative}: #{matches.flatten.uniq.join(', ')}"
        end
        
        break if results.size >= 15
      end
      
      if results.empty?
        "❌ Aucun résultat pour le regex : #{regex}"
      else
        "🔍 Résultats grep pour /#{regex}/ dans #{directory} :\n\n#{results.join("\n")}"
      end
    end

    # === GESTION DE LA CONVERSATION ===

    def add_user_message(content)
      @conversation_history << {
        role: "user",
        content: content
      }
    end

    def add_assistant_message(content)
      @conversation_history << {
        role: "assistant",
        content: content
      }
    end
  end
end
