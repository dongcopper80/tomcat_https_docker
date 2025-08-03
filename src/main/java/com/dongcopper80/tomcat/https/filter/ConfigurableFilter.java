package com.dongcopper80.tomcat.https.filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public class ConfigurableFilter implements Filter {

    private boolean enabled = false;
    private String mode = "none";

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        try (InputStream input = getClass().getClassLoader().getResourceAsStream("config.properties")) {
            Properties props = new Properties();
            props.load(input);

            enabled = Boolean.parseBoolean(props.getProperty("filter.enabled", "false"));
            mode = props.getProperty("filter.mode", "none");

        } catch (IOException e) {
            throw new ServletException("Cannot load config.properties", e);
        }
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        if (enabled) {
            if ("log".equalsIgnoreCase(mode)) {
                System.out.println(">>> Filter triggered: " + request.getRemoteAddr());
            }
            // Bạn có thể thêm logic kiểm tra mode khác ở đây
        }

        chain.doFilter(request, response); // tiếp tục chuỗi
    }

    @Override
    public void destroy() {
    }
}