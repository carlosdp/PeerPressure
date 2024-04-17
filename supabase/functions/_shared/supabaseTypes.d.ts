export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          operationName?: string
          query?: string
          variables?: Json
          extensions?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      archive: {
        Row: {
          archivedon: string
          completedon: string | null
          createdon: string
          data: Json | null
          expirein: unknown
          id: string
          keepuntil: string
          name: string
          on_complete: boolean
          output: Json | null
          priority: number
          retrybackoff: boolean
          retrycount: number
          retrydelay: number
          retrylimit: number
          singletonkey: string | null
          singletonon: string | null
          startafter: string
          startedon: string | null
          state: Database["public"]["Enums"]["job_state"]
        }
        Insert: {
          archivedon?: string
          completedon?: string | null
          createdon: string
          data?: Json | null
          expirein: unknown
          id: string
          keepuntil: string
          name: string
          on_complete: boolean
          output?: Json | null
          priority: number
          retrybackoff: boolean
          retrycount: number
          retrydelay: number
          retrylimit: number
          singletonkey?: string | null
          singletonon?: string | null
          startafter: string
          startedon?: string | null
          state: Database["public"]["Enums"]["job_state"]
        }
        Update: {
          archivedon?: string
          completedon?: string | null
          createdon?: string
          data?: Json | null
          expirein?: unknown
          id?: string
          keepuntil?: string
          name?: string
          on_complete?: boolean
          output?: Json | null
          priority?: number
          retrybackoff?: boolean
          retrycount?: number
          retrydelay?: number
          retrylimit?: number
          singletonkey?: string | null
          singletonon?: string | null
          startafter?: string
          startedon?: string | null
          state?: Database["public"]["Enums"]["job_state"]
        }
        Relationships: []
      }
      interview_messages: {
        Row: {
          content: string
          created_at: string
          id: string
          interview_id: string
          metadata: Json
          role: string
        }
        Insert: {
          content: string
          created_at?: string
          id?: string
          interview_id: string
          metadata?: Json
          role: string
        }
        Update: {
          content?: string
          created_at?: string
          id?: string
          interview_id?: string
          metadata?: Json
          role?: string
        }
        Relationships: [
          {
            foreignKeyName: "interview_messages_interview_id_fkey"
            columns: ["interview_id"]
            isOneToOne: false
            referencedRelation: "interviews"
            referencedColumns: ["id"]
          }
        ]
      }
      interviews: {
        Row: {
          completed_at: string | null
          created_at: string
          id: string
          profile_id: string
        }
        Insert: {
          completed_at?: string | null
          created_at?: string
          id?: string
          profile_id: string
        }
        Update: {
          completed_at?: string | null
          created_at?: string
          id?: string
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "interviews_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      job: {
        Row: {
          completedon: string | null
          createdon: string
          data: Json | null
          expirein: unknown
          id: string
          keepuntil: string
          name: string
          on_complete: boolean
          output: Json | null
          priority: number
          retrybackoff: boolean
          retrycount: number
          retrydelay: number
          retrylimit: number
          singletonkey: string | null
          singletonon: string | null
          startafter: string
          startedon: string | null
          state: Database["public"]["Enums"]["job_state"]
        }
        Insert: {
          completedon?: string | null
          createdon?: string
          data?: Json | null
          expirein?: unknown
          id?: string
          keepuntil?: string
          name: string
          on_complete?: boolean
          output?: Json | null
          priority?: number
          retrybackoff?: boolean
          retrycount?: number
          retrydelay?: number
          retrylimit?: number
          singletonkey?: string | null
          singletonon?: string | null
          startafter?: string
          startedon?: string | null
          state?: Database["public"]["Enums"]["job_state"]
        }
        Update: {
          completedon?: string | null
          createdon?: string
          data?: Json | null
          expirein?: unknown
          id?: string
          keepuntil?: string
          name?: string
          on_complete?: boolean
          output?: Json | null
          priority?: number
          retrybackoff?: boolean
          retrycount?: number
          retrydelay?: number
          retrylimit?: number
          singletonkey?: string | null
          singletonon?: string | null
          startafter?: string
          startedon?: string | null
          state?: Database["public"]["Enums"]["job_state"]
        }
        Relationships: []
      }
      matches: {
        Row: {
          created_at: string
          data: Json
          id: string
          match_accepted_at: string | null
          match_rejected_at: string | null
          matched_profile_id: string
          profile_id: string
        }
        Insert: {
          created_at?: string
          data?: Json
          id?: string
          match_accepted_at?: string | null
          match_rejected_at?: string | null
          matched_profile_id: string
          profile_id: string
        }
        Update: {
          created_at?: string
          data?: Json
          id?: string
          match_accepted_at?: string | null
          match_rejected_at?: string | null
          matched_profile_id?: string
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "matches_matched_profile_id_fkey"
            columns: ["matched_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      messages: {
        Row: {
          created_at: string
          id: string
          match_id: string
          message: string
          sender_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          match_id: string
          message: string
          sender_id: string
        }
        Update: {
          created_at?: string
          id?: string
          match_id?: string
          message?: string
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches_with_votes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      profiles: {
        Row: {
          available_photos: Json
          biographical_data: Json
          birth_date: string
          blocks: Json
          created_at: string
          display_location: string
          first_name: string
          gender: Database["public"]["Enums"]["gender"]
          id: string
          location: unknown
          photo_keys: Json
          preferences: Json
          updated_at: string
          user_id: string | null
        }
        Insert: {
          available_photos?: Json
          biographical_data?: Json
          birth_date: string
          blocks?: Json
          created_at?: string
          display_location: string
          first_name: string
          gender: Database["public"]["Enums"]["gender"]
          id?: string
          location: unknown
          photo_keys?: Json
          preferences?: Json
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          available_photos?: Json
          biographical_data?: Json
          birth_date?: string
          blocks?: Json
          created_at?: string
          display_location?: string
          first_name?: string
          gender?: Database["public"]["Enums"]["gender"]
          id?: string
          location?: unknown
          photo_keys?: Json
          preferences?: Json
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      rounds: {
        Row: {
          active: boolean
          end_time: string
          id: string
          join_balance: number
          name: string
          voting_enabled: boolean
        }
        Insert: {
          active?: boolean
          end_time: string
          id?: string
          join_balance?: number
          name: string
          voting_enabled?: boolean
        }
        Update: {
          active?: boolean
          end_time?: string
          id?: string
          join_balance?: number
          name?: string
          voting_enabled?: boolean
        }
        Relationships: []
      }
      saved_profiles: {
        Row: {
          created_at: string
          profile_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          profile_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          profile_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "saved_profiles_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "saved_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      schedule: {
        Row: {
          created_on: string
          cron: string
          data: Json | null
          name: string
          options: Json | null
          timezone: string | null
          updated_on: string
        }
        Insert: {
          created_on?: string
          cron: string
          data?: Json | null
          name: string
          options?: Json | null
          timezone?: string | null
          updated_on?: string
        }
        Update: {
          created_on?: string
          cron?: string
          data?: Json | null
          name?: string
          options?: Json | null
          timezone?: string | null
          updated_on?: string
        }
        Relationships: []
      }
      subscription: {
        Row: {
          created_on: string
          event: string
          name: string
          updated_on: string
        }
        Insert: {
          created_on?: string
          event: string
          name: string
          updated_on?: string
        }
        Update: {
          created_on?: string
          event?: string
          name?: string
          updated_on?: string
        }
        Relationships: []
      }
      users: {
        Row: {
          display_name: string
          id: string
          matching_profile_id: string | null
          votes_balance: number
        }
        Insert: {
          display_name?: string
          id: string
          matching_profile_id?: string | null
          votes_balance?: number
        }
        Update: {
          display_name?: string
          id?: string
          matching_profile_id?: string | null
          votes_balance?: number
        }
        Relationships: [
          {
            foreignKeyName: "users_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "users_matching_profile_id_fkey"
            columns: ["matching_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      version: {
        Row: {
          cron_on: string | null
          maintained_on: string | null
          version: number
        }
        Insert: {
          cron_on?: string | null
          maintained_on?: string | null
          version: number
        }
        Update: {
          cron_on?: string | null
          maintained_on?: string | null
          version?: number
        }
        Relationships: []
      }
      votes: {
        Row: {
          allocation: number
          created_at: string
          id: string
          match_id: string
          round_id: string
          user_id: string
        }
        Insert: {
          allocation: number
          created_at?: string
          id?: string
          match_id: string
          round_id: string
          user_id: string
        }
        Update: {
          allocation?: number
          created_at?: string
          id?: string
          match_id?: string
          round_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "votes_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "votes_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches_with_votes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "votes_round_id_fkey"
            columns: ["round_id"]
            isOneToOne: false
            referencedRelation: "rounds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      matches_with_votes: {
        Row: {
          created_at: string | null
          data: Json | null
          id: string | null
          match_accepted_at: string | null
          match_rejected_at: string | null
          matched_profile_id: string | null
          profile_id: string | null
          total_votes: number | null
        }
        Relationships: [
          {
            foreignKeyName: "matches_matched_profile_id_fkey"
            columns: ["matched_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Functions: {
      active_interview: {
        Args: Record<PropertyKey, never>
        Returns: {
          completed_at: string | null
          created_at: string
          id: string
          profile_id: string
        }[]
      }
      active_interview_for_profile: {
        Args: {
          profile_id: string
        }
        Returns: {
          completed_at: string | null
          created_at: string
          id: string
          profile_id: string
        }[]
      }
      create_match: {
        Args: {
          profile_id: string
        }
        Returns: undefined
      }
      get_contestant_profiles: {
        Args: Record<PropertyKey, never>
        Returns: {
          available_photos: Json
          biographical_data: Json
          birth_date: string
          blocks: Json
          created_at: string
          display_location: string
          first_name: string
          gender: Database["public"]["Enums"]["gender"]
          id: string
          location: unknown
          photo_keys: Json
          preferences: Json
          updated_at: string
          user_id: string | null
        }[]
      }
      get_likes: {
        Args: Record<PropertyKey, never>
        Returns: Json[]
      }
      get_match: {
        Args: {
          profile_1: string
          profile_2: string
        }
        Returns: {
          created_at: string | null
          data: Json | null
          id: string | null
          match_accepted_at: string | null
          match_rejected_at: string | null
          matched_profile_id: string | null
          profile_id: string | null
          total_votes: number | null
        }
      }
      get_matches: {
        Args: Record<PropertyKey, never>
        Returns: Json[]
      }
      get_matching_profile: {
        Args: Record<PropertyKey, never>
        Returns: {
          available_photos: Json
          biographical_data: Json
          birth_date: string
          blocks: Json
          created_at: string
          display_location: string
          first_name: string
          gender: Database["public"]["Enums"]["gender"]
          id: string
          location: unknown
          photo_keys: Json
          preferences: Json
          updated_at: string
          user_id: string | null
        }
      }
      get_or_create_active_interview_for_profile: {
        Args: {
          profile_id: string
        }
        Returns: {
          completed_at: string | null
          created_at: string
          id: string
          profile_id: string
        }[]
      }
      get_pending_bot_matches: {
        Args: Record<PropertyKey, never>
        Returns: {
          created_at: string
          data: Json
          id: string
          match_accepted_at: string | null
          match_rejected_at: string | null
          matched_profile_id: string
          profile_id: string
        }[]
      }
      get_profile: {
        Args: Record<PropertyKey, never>
        Returns: {
          available_photos: Json
          biographical_data: Json
          birth_date: string
          blocks: Json
          created_at: string
          display_location: string
          first_name: string
          gender: Database["public"]["Enums"]["gender"]
          id: string
          location: unknown
          photo_keys: Json
          preferences: Json
          updated_at: string
          user_id: string | null
        }
      }
      get_unmatched_profiles: {
        Args: Record<PropertyKey, never>
        Returns: {
          available_photos: Json
          biographical_data: Json
          birth_date: string
          blocks: Json
          created_at: string
          display_location: string
          first_name: string
          gender: Database["public"]["Enums"]["gender"]
          id: string
          location: unknown
          photo_keys: Json
          preferences: Json
          updated_at: string
          user_id: string | null
        }[]
      }
      send_message: {
        Args: {
          match_id: string
          message: string
        }
        Returns: undefined
      }
    }
    Enums: {
      gender: "male" | "female" | "non-binary" | "other"
      job_state:
        | "created"
        | "retry"
        | "active"
        | "completed"
        | "expired"
        | "cancelled"
        | "failed"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  storage: {
    Tables: {
      buckets: {
        Row: {
          allowed_mime_types: string[] | null
          avif_autodetection: boolean | null
          created_at: string | null
          file_size_limit: number | null
          id: string
          name: string
          owner: string | null
          owner_id: string | null
          public: boolean | null
          updated_at: string | null
        }
        Insert: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id: string
          name: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          updated_at?: string | null
        }
        Update: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id?: string
          name?: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          updated_at?: string | null
        }
        Relationships: []
      }
      migrations: {
        Row: {
          executed_at: string | null
          hash: string
          id: number
          name: string
        }
        Insert: {
          executed_at?: string | null
          hash: string
          id: number
          name: string
        }
        Update: {
          executed_at?: string | null
          hash?: string
          id?: number
          name?: string
        }
        Relationships: []
      }
      objects: {
        Row: {
          bucket_id: string | null
          created_at: string | null
          id: string
          last_accessed_at: string | null
          metadata: Json | null
          name: string | null
          owner: string | null
          owner_id: string | null
          path_tokens: string[] | null
          updated_at: string | null
          version: string | null
        }
        Insert: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          version?: string | null
        }
        Update: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          version?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "objects_bucketId_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      can_insert_object: {
        Args: {
          bucketid: string
          name: string
          owner: string
          metadata: Json
        }
        Returns: undefined
      }
      extension: {
        Args: {
          name: string
        }
        Returns: string
      }
      filename: {
        Args: {
          name: string
        }
        Returns: string
      }
      foldername: {
        Args: {
          name: string
        }
        Returns: unknown
      }
      get_size_by_bucket: {
        Args: Record<PropertyKey, never>
        Returns: {
          size: number
          bucket_id: string
        }[]
      }
      search: {
        Args: {
          prefix: string
          bucketname: string
          limits?: number
          levels?: number
          offsets?: number
          search?: string
          sortcolumn?: string
          sortorder?: string
        }
        Returns: {
          name: string
          id: string
          updated_at: string
          created_at: string
          last_accessed_at: string
          metadata: Json
        }[]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (Database["public"]["Tables"] & Database["public"]["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (Database["public"]["Tables"] &
      Database["public"]["Views"])
  ? (Database["public"]["Tables"] &
      Database["public"]["Views"])[PublicTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof Database["public"]["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof Database["public"]["Tables"]
  ? Database["public"]["Tables"][PublicTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof Database["public"]["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof Database["public"]["Tables"]
  ? Database["public"]["Tables"][PublicTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof Database["public"]["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof Database["public"]["Enums"]
  ? Database["public"]["Enums"][PublicEnumNameOrOptions]
  : never

