import { rawMessage, generateImage } from './utils.js';
import { createClient } from '@supabase/supabase-js';
import axios from 'axios';

const supabase = createClient('http://localhost:54321', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU');

async function generateProfile(location, age, gender, prompt) {
  console.log(`Generating profile for ${location}, (age: ${age}, gender: ${gender})...`)
  const locationRes = await axios.get(`https://maps.googleapis.com/maps/api/geocode/json?address=${location}&key=${process.env.GOOGLE_MAPS_API_KEY}`);
  const results = locationRes.data.results;

  // find address component that has type "neighborhood", else use locality
  let neighborhood = results[0].address_components.find(c => c.types.includes('neighborhood'));
  if (!neighborhood) {
    neighborhood = results[0].address_components.find(c => c.types.includes('locality'));
  }

  const latlng = results[0].geometry.location;

  const message = await rawMessage('gpt-4-turbo-preview', [
    {
      role: 'system',
      content: `You are an expert synthetic dating profile generator. Generate a dating profile given the following parameters
      Age: ${age}
      Location: ${location}
      Gender: ${gender}

      - You must choose a first name, based on the gender and location
      - Decide whether the person went to school locally, or went away for college`
    }
  ], {
    temperature: 1,
    tools: [
      {
        type: 'function',
        function: {
          name: 'create_profile',
          description: 'Create the profile',
          parameters: {
            type: 'object',
            required: ['name', 'age', 'height'],
            properties: {
              first_name: { type: 'string' },
              height: { type: 'string', description: 'The height of the person, in feet and inches' },
              college: { type: 'string', description: 'The college the person went to' },
            }
          }
        }
      }
    ],
    toolChoice: { type: 'function', function: { name: 'create_profile' } },
  });

  if (message.content) {
    console.error('Error generating profile: content returned from message');
    return;
  }

  const args = JSON.parse(message.tool_calls[0].function.arguments);

  const { data: profile, error } = await supabase.from('profiles').insert({
    first_name: args.first_name,
    // todo: make more random
    birth_date: new Date(new Date().getFullYear() - age, 1, 1),
    gender,
    // POINT
    location: `POINT(${latlng.lat} ${latlng.lng})`,
    display_location: location,
    biographical_data: {
      college: args.college,
    }
  }).select().single();

  if (error) {
    console.error('Error inserting profile into database:', error);

    throw new Error('Error inserting profile into database');
  }

  console.log('Coming up with a profile photo...');

  const imageMessage = await rawMessage('gpt-3.5-turbo', [
    {
      role: 'system',
      content: `You are an expert photographer for dating profile photos. Based on the following dating profile, describe a cool, attractive profile photo for the person. Come up with a detailed description of the person in your description, based on their profile data. The prompt should be simple, for example: "a beautiful blonde haired girl, sitting on the grass with friends in the courtyard of a college campus, fall leaves on the ground, everyone smiling"`
    },
    {
      role: 'user',
      content: JSON.stringify(args),
    },
    {
      role: 'system',
      content: 'Return prompt only in your message',
    }
  ],
  {
    temperature: 0.5,
  });

  if (!imageMessage.content) {
    console.error('Error generating image description: no content returned from message');
    return;
  }

  console.log('Generating profile image...');
  console.log(imageMessage.content);

  const image = await generateImage(`${imageMessage.content}, hyper realistic, natural, real`, '1024x1792', 'natural');
  const imageKey = `${profile.id}/profile/${Math.random().toString(36).substring(7)}.png`;
  console.log(imageKey);

  const { error: imageError } = await supabase.storage.from('photos').upload(imageKey, image, { contentType: 'image/png' });
  if (imageError) {
    console.error('Error uploading profile image to storage:', imageError);
    return;
  }

  const { error: updateError } = await supabase.from('profiles').update({
    profile_photo_key: imageKey,
  }).eq('id', profile.id);
  if (updateError) {
    console.error('Error updating profile photo key:', updateError);
    return;
  }
}

async function main() {
  const args = process.argv.slice(2);
  const options = {
    count: 1,
    age: undefined, 
    location: undefined,
    gender: Math.random() > 0.5 ? 'male' : 'female',
    prompt: undefined,
  };

  // Parse command line arguments
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--help' || arg === '-h') {
      showHelpText();
      return;
    } else if (arg === '--location') {
      options.location = args[i + 1];
      i++;
    } else if (arg === '--age') {
      options.age = parseInt(args[i + 1]);
      i++;
    } else if (arg === '-c' || arg === '--count') {
      options.count = parseInt(args[i + 1]);
      i++;
    } else if (arg === '--gender') {
      options.gender = args[i + 1];
      i++;
    } else if (arg === '--prompt') {
      options.prompt = args[i + 1];
      i++;
    } else {
      console.log(`Invalid argument: ${arg}`);
      showHelpText();
      return;
    }
  }

  // Validate options
  if (!options.location) {
    console.log('Error: --location is required');
    showHelpText();
    return;
  }

  if (!options.age) {
    console.log('Error: --age is required');
    showHelpText();
    return;
  }

  // Generate profiles based on options
  for (let i = 0; i < options.count; i++) {
    await generateProfile(options.location, options.age, options.gender, options.prompt);
  }

  console.log('Profiles generated successfully!');
}

function showHelpText() {
  console.log('Usage: node generateProfiles.js [options]');
  console.log('Options:');
  console.log('  --location <location>  Generate profiles for this location (required)');
  console.log('  --age <age>            Generate profiles for this age (required)');
  console.log('  -c, --count <number>   The amount of profiles to generate (default: 1)');
  console.log('  --gender <gender>      Only generate profiles for this gender');
  console.log('  --prompt <description> A description of the kind of profile to generate');
}

main();
