
-- 22.0.0  Using Cortex LLM Functions
--         The purpose of this lab is to familiarize you with the Snowflake
--         Cortex LLM functions and allow you to practice using some of the
--         specialized LLM functions.
--         Snowflake Cortex LLM functions use large language models (LLMs) to
--         extract insights from data stored in unstructured and semi-structured
--         formats.
--         Snowflake fully hosts and manages these LLMs, so using them requires
--         no setup. Your data stays within Snowflake giving you the
--         performance, scalability, and governance you expect.
--         Snowflake Cortex LLM features are provided as SQL functions and are
--         also available in Python.
--         - Use the SENTIMENT LLM function.
--         - Use the EXTRACT_ANSWER LLM function.
--         - Use the TRANSLATE LLM function.
--         - Use the SUMMARIZE LLM function.
--         HOW TO COMPLETE THIS LAB
--         Since the workbook PDF has useful diagrams and illustrations (not
--         present in the .SQL files), we recommend that you read the
--         instructions from the workbook PDF. In order to execute the code
--         presented in each step, use the SQL code file provided for this lab.
--         OPENING THE SQL FILE
--         To load an SQL file, in the left navigation bar, select Projects,
--         then select Worksheets. From the Worksheets page, in the upper-right
--         corner, click the ellipsis (…) to the left of the blue plus (+)
--         button. Select Create Worksheet from SQL File from the drop-down
--         menu. Navigate to the SQL file for the lab and load it.
--         Let’s get started!

-- 22.1.0  Introduction
--         Working with SENTIMENT, EXTRACT_ANSWER, TRANSLATE, and SUMMARIZE is
--         straightforward. Like any other regular function, you call them,
--         passing in required parameters and returning text or numeric output.
--         Under the covers, Snowflake powers these services with models from
--         the likes of Mistral, Meta, Google, Reka (and Snowflake!) and will
--         train the base models or change the models over time to provide the
--         best results for the output. You do not need to engineer prompts or
--         determine the appropriate model for a specific use case - this is
--         taken care of for you. These convenience functions can be used to
--         quickly and cost-effectively execute routine tasks.
--         The COMPLETE() function is quite different from the specialized
--         functions and is capable of performing each of their tasks. It is
--         more complex to work with but offers options the specialized
--         functions do not, such as the ability to select a specific model to
--         work with and even configure select parameters.

-- 22.1.1  A word about tokens.
--         In working with Snowflake Cortex LLM functions, tokens are the unit
--         of measurement that dictates the cost of requests to a model. It
--         measures the input submitted and output generated, metered to
--         determine how you are charged for access to these services. Models of
--         different families and types have a range of input and output
--         capabilities, along with requisite costs.
--         Tokens generally correspond to words, but not all tokens are words,
--         so the number of words corresponding to a limit is slightly less than
--         the number of tokens. One useful approximation is to total the number
--         of words and multiply it by 1.5 to estimate the tokens it will
--         consume.
--         To ensure that all Snowflake customers can access LLM capabilities,
--         Snowflake Cortex LLM functions may be subject to throttling during
--         periods of high utilization. Usage quotas are not applied at the
--         account level. Throttled requests will receive an error response and
--         should be retried later.

-- 22.2.0  Specialized LLM Function: SENTIMENT
--         This LLM function aims to detect the mood or tone of the given
--         English-language text. The function returns a sentiment score from -1
--         to 1, representing the text’s detected negative or positive
--         sentiment.
--         This function takes a single parameter, the English-language input
--         text you want analyzed. It returns a floating-point number from -1 to
--         1 (inclusive), indicating the text’s negative or positive sentiment
--         level. Values around 0 indicate neutral sentiment.
--         Snowflake credits per million tokens: 0.08
--         Context window (tokens): 512
--         The context window specifies the maximum number of tokens the
--         function can accept. For SENTIMENT(), this is a limit on the input.
--         For functions that generate new text in the response (COMPLETE(),
--         SUMMARIZE(), and TRANSLATE()), both input and output tokens are
--         counted. Requests that exceed the context window limit result in an
--         error.

-- 22.2.1  Set your context.

USE ROLE training_role;

CREATE WAREHOUSE IF NOT EXISTS FALCON_wh;
USE WAREHOUSE FALCON_wh;

CREATE DATABASE IF NOT EXISTS FALCON_db;

CREATE SCHEMA IF NOT EXISTS FALCON_db.llm;
USE SCHEMA FALCON_db.llm;


-- 22.2.2  Use the SENTIMENT function.
--         First, let’s run the function across a negative review based on a
--         consumer’s experience interacting with one of our vending machines.
--         Execute the following:

SELECT snowflake.cortex.SENTIMENT('The vending machine was lousy! It swallowed my coins and served up an awful selection of products. I would not use this machine again!') AS sentiment_grading;

--         Note that the LLM function correctly identifies the negative tone of
--         this comment with a return value edging towards -1.0.
--         Now, try a positive comment. The function can be run against columns
--         in a table, but we set a session variable in this example and pass
--         that in. You should see the function correctly identifies the
--         strongly positive tone of this comment.

SET input_text = 'What a delightful experience. The vending machine was in the perfect location and literally saved my life - I was famished.';

SELECT snowflake.cortex.SENTIMENT($input_text) AS sentiment_grading;

--         The numeric return value allows us to order our results
--         hierarchically by sentiment. We can also derive labels based on these
--         values. The following example is a simple demonstration of this
--         approach, which may require additional tweaking for accuracy. The
--         function should help us classify the input text as neutral. Execute
--         the statements to confirm.

SET input_text = 'The vending machine provides food and beverages.';

SELECT snowflake.cortex.SENTIMENT($input_text) AS sentiment_grading,
    CASE
        WHEN (sentiment_grading >= 0.075) THEN 'POSITIVE'
        WHEN (sentiment_grading <= -0.075) THEN 'NEGATIVE'
        ELSE 'NEUTRAL'
    END as sentiment_label;


-- 22.3.0  Specialized LLM Function: EXTRACT_ANSWER
--         This LLM function aims to extract an answer to a given question from
--         a text document and return it if it can be found in the data. By
--         document, we mean text in plain English or a string representation of
--         a semi-structured (JSON) data object.
--         Snowflake credits per million tokens: 0.08
--         Context window (tokens): 2,048 for text, 64 for question

-- 22.3.1  Use the EXTRACT_ANSWER function.
--         The function takes in two parameters: the source document and the
--         question asked based on the document text.
--         Let’s try a simple example.

SET source_document = 'May 2024 Vending Machine Sales Results: a total of 10013 products sold across 20 machines';

SET my_question = 'how many products were sold in vending machines in May?';

SELECT snowflake.cortex.EXTRACT_ANSWER($source_document, $my_question);

--         You will see that the result returned is a JSON array containing a
--         single object with two key-pair values - the answer to your question
--         and a score that provides the numerical confidence in the answer
--         (closer to 1.0 is better).
--         We can extract the answer and format it for presentation as follows:

SELECT snowflake.cortex.EXTRACT_ANSWER($source_document, $my_question) AS response,
        $my_question AS question,
        response[0]."answer"::STRING AS answer;

--         Although this function helps pinpoint and retrieve specific pieces of
--         information from a source document, it does not have the ability to
--         reason over that content (that is where the COMPLETE function comes
--         in). So, if we try to ask it to extrapolate, we will receive
--         incorrect results.
--         Let’s take a look at an example. In the following, I’m asking a
--         question for which the function does not have access to the answer.
--         The source document does not contain information about average sales,
--         even though it is a small step for a human to calculate this value
--         based on the known number of sales and total vending machines:

SET my_question = 'what was the average number of products sold per vending machine in May?';

-- You will see that the following response is incorrect...
SELECT snowflake.cortex.EXTRACT_ANSWER($source_document, $my_question) AS response,
        $my_question AS question,
        response[0]."answer"::STRING AS answer;

--         You can use the EXTRACT_ANSWER() function to retrieve values from the
--         document, but it is not capable of extrapolating or deriving answers
--         based on the material in the document.

-- 22.4.0  Specialized LLM Function: TRANSLATE
--         The purpose of this LLM function is straightforward - to translate
--         the given input text from one supported language to another. The
--         function returns a string containing a translation of the original
--         text into the target language.
--         Snowflake credits per million tokens: 0.33
--         Context window (tokens): 1024

-- 22.4.1  Use the TRANSLATE function.
--         The function takes in three parameters. The first is the text to
--         translate, and the second and third are language code identifiers for
--         the source and target languages. Currently, eleven different
--         languages are supported: English (en), French (fr), German (de),
--         Italian (it), Japanese (ja), Korean (ko), Polish (pl), Portuguese
--         (pt), Russian (ru), Spanish (es), and Swedish (sv).
--         Let’s try this with a simple example. First, define a phrase you wish
--         to translate. We will create one related to an issue with one of our
--         vending machines.

SET source_text = 'The underlying issue with the cooling capabilities of the vending machine (id AEX-5002-xam) was due to a faulty gasket in the compression component.';

--         Now run this through the function specifying the correct language
--         identifier codes to convert this from English to Swedish.

SELECT snowflake.cortex.TRANSLATE($source_text, 'en', 'sv') AS translated_to_swedish;

--         If your Swedish is good, that is no problem; otherwise, you may want
--         to validate the result using an external tool (such as Google
--         Translate).
--         Run this a second time, this time specifying Korean as the target
--         language:

SELECT snowflake.cortex.TRANSLATE($source_text, 'en', 'ko') AS translated_to_korean;

--         Using the following approach, we can convert the result from Korean
--         back to English and verify that the original sense of the phrase has
--         been retained. Execute the following to confirm:

SELECT snowflake.cortex.TRANSLATE(translated_to_korean, 'ko', 'en') AS translated_back_to_english
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

--         One feature of the function worth noting is that if the source
--         language code is an empty string, ’’, the source language is
--         automatically detected. Run the following to translate the following
--         Italian text into English without indicating the language of origin:

SET source_text = 'Si prega di prendere in considerazione la possibilità di spostare questo distributore automatico dalla sua posizione attuale, o almeno di migliorare l\'illuminazione per motivi di sicurezza - grazie per la vostra considerazione.';

SELECT snowflake.cortex.TRANSLATE($source_text, '', 'en') AS translated_to_english;

--         TRANSLATED_TO_ENGLISH In the result, you should find a polite
--         recommendation from one of our customers.

-- 22.5.0  Specialized LLM Function: SUMMARIZE
--         This LLM function provides a synopsis of the given English-language
--         input text. The model underpinning this function supports a generous
--         context window of 32,000 tokens, which is around 20,000 words, using
--         a rough heuristic of 1 word, equating to approximately 1.5 tokens.
--         Snowflake credits per million tokens: 0.10
--         Context window (tokens): 32,000

-- 22.5.1  Use the SUMMARIZE function.
--         Let’s try this with a simple example. First, let’s create some sample
--         text we want to be summarized. In this instance, we will create a
--         temporary table with a single STRING column to contain our text, as
--         we want something more substantial to work with than the limit for
--         session variables.
--         Execute the following to create the table and insert a row of text
--         outlining issues encountered during an inspection of one of our
--         vending machines.

USE SCHEMA FALCON_db.llm;

CREATE OR REPLACE TEMPORARY TABLE source (text STRING);

INSERT INTO source VALUES (
    'The underlying issue with the cooling capabilities of the vending machine (id AEX-5002-xam) was due to a faulty gasket in the compression component. ' ||
    'During the routine inspection, we also noted a couple of additional issues: ' ||
    'a) corrosion appearing on the boundary of the coin slot mechanism and a weakened spring that requires replacement ' ||
    'b) chipped paint on the main panel of the machine, which appears to have been caused by impact from a blunt instrument, and c) unseemly graffiti (paint) on the right edge.'
 ); 

--         Now, run this text through the function. Note that the function takes
--         in a single parameter.

SELECT snowflake.cortex.SUMMARIZE(text) AS summary
FROM source;

--         As you can see, the function correctly distills the key themes from
--         the source text shown above, producing an output of 36 words from the
--         original text, which contains 84 words.

-- 22.5.2  SUMMARIZE function operation.
--         One point worth noting about this function is that you cannot point
--         it at a URL and expect it to summarize the content at that location.
--         It does not attempt to read the content at that endpoint. Instead, it
--         flatly assesses the input provided to it as text and so will take
--         cues from the URL components (domain, path, and so on) to generate a
--         response.
--         In some cases, you may get lucky and have a very reasonable response
--         when entering a URL based on the text included in the URL alone, as
--         shown in the following example. Try this:

SELECT snowflake.cortex.summarize(
'https://quickstarts.snowflake.com/guide/
getting_started_with_snowpark_in_snowflake_python_worksheets/index.html'
) AS summary;

--         However, to run this function across some web content, you must
--         scrape/download this as an initial step before passing it to
--         SUMMARIZE().

-- 22.5.3  Suspend your virtual warehouse.

ALTER WAREHOUSE FALCON_wh SUSPEND;


-- 22.6.0  Key Takeaways
--         - Working with SENTIMENT, EXTRACT_ANSWER, TRANSLATE, and SUMMARIZE is
--         straightforward. Like any other regular function, you call them,
--         passing in required parameters and returning text or numeric output.
--         - In working with Snowflake Cortex LLM functions, tokens are the unit
--         of measurement that dictates the cost of requests to a model.
--         - The context window specifies the maximum number of tokens the
--         function can accept.
