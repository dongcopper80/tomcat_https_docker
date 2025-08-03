package com.dongcopper80.tomcat.https.filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;    
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.Properties;

/**
 * CorsFilter is a servlet filter that handles CORS (Cross-Origin Resource Sharing) requests.
 * It sets the appropriate headers to allow cross-origin requests and handles preflight OPTIONS requests.
 */

public class CorsFilter implements Filter {

    private Properties corsConfig = new Properties();

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        try (InputStream input = filterConfig.getServletContext()
                .getResourceAsStream("/WEB-INF/classes/cors.properties")) {
            corsConfig.load(input);
        } catch (IOException e) {
            throw new ServletException("Failed to load CORS configuration", e);
        }
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String originHeader = req.getHeader("Origin");
        String allowedOrigins = corsConfig.getProperty("cors.allowed.origins", "*");

        if ("*".equals(allowedOrigins) || Arrays.asList(allowedOrigins.split(",")).contains(originHeader)) {
            res.setHeader("Access-Control-Allow-Origin", originHeader != null ? originHeader : "*");
        }

        res.setHeader("Access-Control-Allow-Methods", corsConfig.getProperty("cors.allowed.methods", "GET,POST,OPTIONS"));
        res.setHeader("Access-Control-Allow-Headers", corsConfig.getProperty("cors.allowed.headers", "Content-Type"));
        res.setHeader("Access-Control-Allow-Credentials", corsConfig.getProperty("cors.allow.credentials", "true"));
        res.setHeader("Access-Control-Max-Age", corsConfig.getProperty("cors.max.age", "3600"));

        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) {
            res.setStatus(HttpServletResponse.SC_OK);
            return;
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {}
}