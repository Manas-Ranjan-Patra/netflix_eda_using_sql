CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);

select * from netflix;

SELECT 
	COUNT(*) 
FROM netflix;


-- 1. Count the number of Movies vs TV Shows

SELECT type, COUNT(*)
FROM netflix
GROUP BY type;

-- 2. Find the most common rating for movies and TV shows

SELECT type , rating, count
from
(SELECT type,rating,Count(*),
Rank() over(Partition By type Order by Count(*) DESC)
FROM netflix
GROUP BY type,rating
) as t1
where rank =1;

-- 3. List all movies released in a specific year (e.g., 2020)

CREATE OR REPLACE FUNCTION list_of_movie(p_year int)
RETURNS TABLE(title varchar(250))
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT n.title FROM netflix as n
        WHERE n.type='Movie' AND n.release_year = p_year;
END;
$$;

SELECT * FROM list_of_movie(2020);

-- 4. Find the top 5 countries with the most content on Netflix

SELECT 
	UNNEST(STRING_TO_ARRAY(country,',')) AS country,
COUNT(*) AS total_content
FROM netflix
GROUP BY 1
ORDER BY total_content DESC
LIMIT 5;

-- 5. Identify the longest movie

SELECT *
FROM netflix
WHERE type='Movie' and duration is not null
ORDER BY SPLIT_PART(duration, ' ', 1)::int DESC
LIMIT 1;

-- 6. Find content added in the last 5 years

SELECT *
FROM netflix
WHERE TO_DATE(date_added, 'DD-Mon-YY') >= CURRENT_DATE - INTERVAL '5 years';

-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!

SELECT * 
FROM netflix
WHERE director ILIKE '%Rajiv Chilaka%';

-- 8. List all TV shows with more than 5 seasons

SELECT *
FROM netflix
WHERE type='TV Show' and duration is not null
and SPLIT_PART(duration, ' ', 1)::int >=5;

-- 9. Count the number of content items in each genre

SELECT 
    UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS genre,
    COUNT(*) AS total_content
FROM netflix
GROUP BY 1;

-- 10.Find each year and the average numbers of content release in India on netflix.

SELECT 
    country,
    release_year,
    COUNT(show_id) AS total_release,
    ROUND(
        COUNT(show_id)::numeric /
        (SELECT COUNT(show_id) FROM netflix WHERE country = 'India')::numeric * 100, 2
    ) AS avg_release
FROM netflix
WHERE country = 'India'
GROUP BY country, release_year
ORDER BY avg_release DESC
LIMIT 5;

-- 11. Return top 5 year with highest avg content release!

SELECT 
	release_year,
	count(*) as total_content,
	ROUND(count(*):: numeric/(
	SELECT COUNT(n.*) FROM netflix n) ::numeric *100 ,2 )as avg_content
FROM netflix ne
GROUP BY release_year
ORDER BY total_content DESC
LIMIT 5;

-- 12. List all movies that are documentaries

SELECT title as movies
FROM netflix
WHERE type ='Movie' and listed_in ILIKE '%documentaries%';

-- 13. Find all content without a director

SELECT title as movies
FROM netflix
WHERE director IS NULL;

-- 14. Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT * 
FROM netflix
WHERE casts LIKE '%Salman Khan%'
  AND release_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10;
  

-- 15. Find the top 10 actors who have appeared in the highest number of movies produced in India.

SELECT 
	UNNEST(STRING_TO_ARRAY(casts,',')) as actors,
	COUNT(*) as most_appearance
FROM netflix
WHERE country ='India'
GROUP BY actors
ORDER BY most_appearance DESC 
LIMIT 10;

/*
16.
Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.
*/

SELECT 
	CASE
		WHEN description ILIKE '%kill%' or description ILIKE '%violence%' THEN 'Bad'
		ELSE 'Good'
	END as content_label,
	COUNT(*)
FROM netflix
GROUP BY content_label;

