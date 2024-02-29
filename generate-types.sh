#!/bin/sh
supabase gen types typescript --local | tee supabase/functions/_shared/supabaseTypes.d.ts > /dev/null
